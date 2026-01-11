import 'package:flutter/material.dart';

import '../widgets/track_feed_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_TrackItem> _items = [
    _TrackItem(trackTitle: 'Down bad', artistName: 'Taylor Swift'),
    _TrackItem(trackTitle: 'High', artistName: 'The Chainsmokers'),
    _TrackItem(trackTitle: 'Blue Lights', artistName: 'Jorja Smith'),
    _TrackItem(trackTitle: 'Sunset Lover', artistName: 'Petit Biscuit'),
    _TrackItem(trackTitle: 'Electric', artistName: 'Alina Baraz'),
    _TrackItem(trackTitle: 'Midnight City', artistName: 'M83'),
    _TrackItem(trackTitle: 'Blinding Lights', artistName: 'The Weeknd'),
  ];

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_TrackItem> filteredItems = _items.where((item) {
      if (_query.isEmpty) {
        return true;
      }
      final String lower = _query.toLowerCase();
      return item.trackTitle.toLowerCase().contains(lower) ||
          item.artistName.toLowerCase().contains(lower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Feed'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tracks or artists',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return TrackFeedCard(
                    trackTitle: item.trackTitle,
                    artistName: item.artistName,
                    isLiked: item.isLiked,
                    onLikeToggle: () {
                      setState(() {
                        item.isLiked = !item.isLiked;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackItem {
  _TrackItem({
    required this.trackTitle,
    required this.artistName,
    this.isLiked = false,
  });

  final String trackTitle;
  final String artistName;
  bool isLiked;
}
