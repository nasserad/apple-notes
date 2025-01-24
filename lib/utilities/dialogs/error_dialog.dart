import 'package:apple_notes/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String text) {
  return showGenericDialog<void>(
    context: context,
    title: 'An Error Occurred :()',
    content: text,
    optionsBuilder: () => {
      'Dismiss': null,
    },
  );
}

// Future<void> showErrorDialog(
//   BuildContext context,
//   String text,
// ) {
//   return showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text('An error occured.'),
//         content: Text('Error: $text.'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: const Text('Dismiss'),
//           )
//         ],
//       );
//     },
//   );
// }
