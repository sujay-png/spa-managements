import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/views/services/services_data.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
  });

  final Services service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(service.name),
        subtitle: Text(service.description),
      ),
    );
  }
}