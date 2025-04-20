import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../models/request_model.dart';

class RequestsTab extends StatelessWidget {
  const RequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for requests
    final List<Request> requests = [
      Request(productName: 'T-Shirt', customerName: 'John Doe', date: 'April 8, 2024'),
      Request(productName: 'Laptop', customerName: 'Jane Smith', date: 'April 8, 2024'),
      Request(productName: 'Headphones', customerName: 'Alice Johnson', date: 'April 7, 2024'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requests',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requests[index].productName,
                        style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requests[index].customerName,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requests[index].date,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}