import 'package:flutter/material.dart';
import 'package:foodbank/features/food_post/domain/entities/food_post_entity.dart';
import 'create_food_post_page.dart';

class EditFoodPostPage extends StatelessWidget {
  final FoodPostEntity post;

  const EditFoodPostPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return CreateFoodPostPage(initialPost: post);
  }
}
