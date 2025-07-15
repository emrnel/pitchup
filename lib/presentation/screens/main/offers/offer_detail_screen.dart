import 'package:flutter/material.dart';

class OfferDetailScreen extends StatelessWidget {
  final String offerId;

  OfferDetailScreen({required this.offerId});

  @override
  Widget build(BuildContext context) {
    // Placeholder for offer details
    return Scaffold(
      appBar: AppBar(
        title: Text('Offer Details'),
      ),
      body: Center(
        child: Text('Details for offer ID: $offerId'),
      ),
    );
  }
}