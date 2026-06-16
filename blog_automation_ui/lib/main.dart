// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert' show jsonDecode, jsonEncode;

void main() => runApp(const AdvancedBlogAutomationApp());

class AdvancedBlogAutomationApp extends StatelessWidget {
  const AdvancedBlogAutomationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA Content Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        cardColor: const Color(0xFF16161A),
        useMaterial3: true,
      ),
      home: const MainNavigationHub(),
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedNavigationIndex = 0;
  List<double> _latencyDataPoints = [1.8, 2.5, 2.1, 3.4, 2.8, 4.2];

  void _updateTelemetryMetrics(List<double> targetData) {
    setState(() => _latencyDataPoints = targetData);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ContentWorkspaceScreen(onMetricsCompiled: _updateTelemetryMetrics),
      AnalyticsDashboardScreen(latencyHistory: _latencyDataPoints),
      const Center(child: Text('Integration API Configuration Settings', style: TextStyle(color: Colors.teal))),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedNavigationIndex,
            onDestinationSelected: (index) => setState(() => _selectedNavigationIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF16161A),
            selectedIconTheme: const IconThemeData(color: Colors.teal),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.edit_note), label: Text('Workspace')),
              NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Analytics')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF24242B)),
          Expanded(child: screens[_selectedNavigationIndex]),
        ],
      ),
    );
  }
}

class ContentWorkspaceScreen extends StatefulWidget {
  final ValueChanged<List<double>> onMetricsCompiled;
  const ContentWorkspaceScreen({super.key, required this.onMetricsCompiled});

  @override
  State<ContentWorkspaceScreen> createState() => _ContentWorkspaceScreenState();
}

class _ContentWorkspaceScreenState extends State<ContentWorkspaceScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _insightsController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _publishToDevTo = true;
  bool _generateLinkedInPromo = true;

  late TabController _outputTabController;
  final String _backendUrl = 'http://localhost:8000/api';
  List<dynamic> _suggestions = [];
  bool _isLoadingTrends = false;
  bool _isPipelineExecuting = false;

  String _generatedMarkdown = "";
  String _generatedImagePrompt = "";
  String _generatedSocialCopy = "";

  @override
  void initState() {
    super.initState();
    _outputTabController = TabController(length: 3, vsync: this);
    _fetchTrendSuggestions();
  }

  Future<void> _fetchTrendSuggestions() async {
    if (!mounted) return;
    setState(() => _isLoadingTrends = true);
    try {
      final response = await http.get(Uri.parse('$_backendUrl/suggestions'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => _suggestions = jsonDecode(response.body)['ideas'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Trends fetch fallback: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTrends = false);
    }
  }

  Future<void> _executeAdvancedPipeline() async {
    if (_topicController.text.trim().isEmpty) return;

    setState(() => _isPipelineExecuting = true);
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-blog-draft'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': _topicController.text,
          'raw_insights': _insightsController.text,
          'raw_code': _codeController.text.isEmpty ? null : _codeController.text,
          'targets': {'devto': _publishToDevTo, 'linkedin': _generateLinkedInPromo}
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final result = jsonDecode(response.body);
        setState(() {
          _generatedMarkdown = result['blog_markdown'] ?? '';
          _generatedImagePrompt = result['image_prompt'] ?? '';
          _generatedSocialCopy = result['linkedin_copy'] ?? '';
        });
        
        final metricsRes = await http.get(Uri.parse('$_backendUrl/analytics'));
        if (metricsRes.statusCode == 200) {
          final List<dynamic> history = jsonDecode(metricsRes.body)['metrics']['latency_history'];
          widget.onMetricsCompiled(history.map((e) => (e as num).toDouble()).toList());
        }

        _outputTabController.animateTo(0);
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Execution Failure: $e')));
    } finally {
      if (mounted) setState(() => _isPipelineExecuting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Content Kit Generated!'),
        content: const Text('Resilient processing loop completed successfully. Check your updated markdown components, live illustration view layout panels, and optimized LinkedIn descriptions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Perfect')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Trend Discovery Base', style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _isLoadingTrends
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: LinearProgressIndicator(color: Colors.teal))
                    : SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final item = _suggestions[index];
                            return GestureDetector(
                              onTap: () {
                                _topicController.text = item['title'] ?? '';
                                _insightsController.text = "Focus Outline Points:\n${item['brief_outline'] ?? ''}";
                              },
                              child: Container(
                                width: 250,
                                margin: const EdgeInsets.only(right: 12.0),
                                child: Card(
                                  color: const Color(0xFF16161A),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 24),
                const Text('Content Construction Controllers', style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'Main Topic / Title', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _insightsController, maxLines: 4, decoration: const InputDecoration(labelText: 'Raw Context Base, Musings, or Error Logs', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _codeController, maxLines: 4, style: const TextStyle(fontFamily: 'monospace', fontSize: 13), decoration: const InputDecoration(labelText: 'Raw Code Block Input (To Review & Optimize)', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                const Text('Distribution Channels & Automation Steps', style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold)),
                CheckboxListTile(title: const Text('Push Draft to Dev.to Integration API', style: TextStyle(fontSize: 13)), value: _publishToDevTo, onChanged: (val) => setState(() => _publishToDevTo = val ?? false), activeColor: Colors.teal),
                CheckboxListTile(title: const Text('Orchestrate LinkedIn Promo Copy Text', style: TextStyle(fontSize: 13)), value: _generateLinkedInPromo, onChanged: (val) => setState(() => _generateLinkedInPromo = val ?? false), activeColor: Colors.teal),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: _isPipelineExecuting ? null : _executeAdvancedPipeline,
                    icon: _isPipelineExecuting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.bolt),
                    label: const Text('Launch Advanced Production Pipeline'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF24242B)),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              TabBar(
                controller: _outputTabController,
                indicatorColor: Colors.teal,
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                tabs: const [Tab(text: "Markdown Blog"), Tab(text: "Image Visual"), Tab(text: "LinkedIn Promo")],
              ),
              Expanded(
                child: TabBarView(
                  controller: _outputTabController,
                  children: [
                    Padding(padding: const EdgeInsets.all(16.0), child: SingleChildScrollView(child: Text(_generatedMarkdown.isEmpty ? 'Your Markdown draft will render here.' : _generatedMarkdown, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)))),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_generatedImagePrompt.isEmpty ? 'AI text illustration parameter strings output here.' : 'Engineered Visual Prompt: "$_generatedImagePrompt"'),
                            const SizedBox(height: 20),
                            _generatedImagePrompt.isEmpty 
                                ? const SizedBox.shrink()
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      'https://image.pollinations.ai/p/${Uri.encodeComponent(_generatedImagePrompt)}?width=1024&height=512&nologo=true&seed=42',
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: Colors.teal)));
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.all(16.0), child: SingleChildScrollView(child: Text(_generatedSocialCopy.isEmpty ? 'Your ready-to-use social summary outputs here.' : _generatedSocialCopy))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalyticsDashboardScreen extends StatelessWidget {
  final List<double> latencyHistory;
  const AnalyticsDashboardScreen({super.key, required this.latencyHistory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Performance Metrics Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 6),
          const Text('Real-time execution latency tracking per content kit generation run.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              color: const Color(0xFF16161A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF24242B))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 32, 16),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: const FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: latencyHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        barWidth: 4,
                        color: Colors.teal,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [Colors.teal.withOpacity(0.3), Colors.teal.withOpacity(0.01)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, color: Colors.teal),
              const SizedBox(width: 8),
              const Text('Pipeline Round-trip Response Duration Latency (Seconds)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}