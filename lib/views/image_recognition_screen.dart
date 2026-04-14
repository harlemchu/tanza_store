// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import '../controllers/database_helper.dart';
// import '../models/code_item.dart';
// import 'details_screen.dart';
// import 'add_edit_screen.dart';

// class ImageRecognitionScreen extends StatefulWidget {
//   const ImageRecognitionScreen({super.key});

//   @override
//   State<ImageRecognitionScreen> createState() => _ImageRecognitionScreenState();
// }

// class _ImageRecognitionScreenState extends State<ImageRecognitionScreen> {
//   final ImagePicker _picker = ImagePicker();
//   bool _isProcessing = false;

//   Future<void> _takePhotoAndRecognize() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);
//     if (pickedFile == null) return;

//     setState(() => _isProcessing = true);

//     final imageFile = File(pickedFile.path);
//     final inputImage = InputImage.fromFile(imageFile);
//     final imageLabeler = ImageLabeler(options: ImageLabelerOptions());
//     final labels = await imageLabeler.processImage(inputImage);
//     await imageLabeler.close();

//     setState(() => _isProcessing = false);

//     if (labels.isEmpty) {
//       _showNoLabelsDialog();
//       return;
//     }

//     // Take the label with highest confidence
//     final bestLabel =
//         labels.reduce((a, b) => a.confidence > b.confidence ? a : b);
//     await _handleLabel(bestLabel.label);
//   }

//   Future<void> _handleLabel(String label) async {
//     final db = DatabaseHelper();
//     final allCodes = await db.getAllCodes();

//     final matches = allCodes
//         .where((item) =>
//             item.name.toLowerCase().contains(label.toLowerCase()) ||
//             item.description.toLowerCase().contains(label.toLowerCase()))
//         .toList();

//     if (matches.isEmpty) {
//       final shouldAdd = await showDialog<bool>(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: const Text('Product Not Found'),
//           content: Text('No product matches "$label".\nDo you want to add it?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, true),
//               child: const Text('Add'),
//             ),
//           ],
//         ),
//       );
//       if (shouldAdd == true && mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const AddEditScreen(
//               code: '',
//               type: 'image',
//               isEditing: false,
//             ),
//           ),
//         );
//       } else {
//         if (mounted) Navigator.pop(context);
//       }
//       return;
//     }

//     if (matches.length == 1) {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => DetailsScreen(codeItem: matches.first),
//           ),
//         );
//       }
//     } else {
//       if (mounted) {
//         showModalBottomSheet(
//           context: context,
//           builder: (ctx) => ListView.builder(
//             itemCount: matches.length,
//             itemBuilder: (ctx, idx) => ListTile(
//               leading: Icon(matches[idx].type == 'qr'
//                   ? Icons.qr_code
//                   : Icons.barcode_reader),
//               title: Text(matches[idx].name),
//               subtitle: Text(matches[idx].code),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => DetailsScreen(codeItem: matches[idx]),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       }
//     }
//   }

//   void _showNoLabelsDialog() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('No Labels Detected'),
//         content:
//             const Text('Could not identify the product. Try a clearer photo.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Image Recognition'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
//             const SizedBox(height: 20),
//             const Text('Take a photo of the product'),
//             const SizedBox(height: 20),
//             if (_isProcessing)
//               const CircularProgressIndicator()
//             else
//               ElevatedButton.icon(
//                 onPressed: _takePhotoAndRecognize,
//                 icon: const Icon(Icons.camera),
//                 label: const Text('Take Photo'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
