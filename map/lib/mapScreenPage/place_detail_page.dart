import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map/models/favorite_place.dart';

/// A StatefulWidget to display details of a place, including Wikipedia content.
class PlaceDetailPage extends StatefulWidget {
  final FavoritePlace place;

  const PlaceDetailPage({Key? key, required this.place}) : super(key: key);

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  String? wikipediaContent; // Stores fetched Wikipedia content
  bool isLoading = true; // Indicates if Wikipedia content is being loaded

  @override
  void initState() {
    super.initState();
    fetchWikipediaContent(widget.place.name); // Fetch Wikipedia content for the given place name
  }

  /// Fetches Wikipedia content using the place name.
  Future<void> fetchWikipediaContent(String title) async {
    final String url =
        'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro&explaintext&titles=${Uri.encodeComponent(title)}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map;

        if (pages.isNotEmpty) {
          // Extract content from the first page of the response
          final firstPage = pages.values.first;
          setState(() {
            wikipediaContent = firstPage['extract'] ?? 'No content available.';
          });
        } else {
          setState(() {
            wikipediaContent = 'No content available.';
          });
        }
      } else {
        setState(() {
          wikipediaContent = 'Failed to load content.';
        });
      }
    } catch (e) {
      setState(() {
        wikipediaContent = 'Error fetching content: $e';
      });
    } finally {
      setState(() {
        isLoading = false; // Stop loading indicator after the request completes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image of the place
            Image.network(
              widget.place.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey,
                child: const Center(
                  child: Text(
                    'Image not available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            // Display the description of the place
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.place.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),

            // Divider for better visual separation
            const Divider(thickness: 1),

            // Title for Wikipedia Information
           const Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Wikipedia Information",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Display loading indicator or the fetched Wikipedia content
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  wikipediaContent ?? 'No information available.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
