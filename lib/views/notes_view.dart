import 'package:apple_notes/constants/routes.dart';
import 'package:apple_notes/enums/menu_action.dart';
import 'package:apple_notes/services/auth/auth_service.dart';
import 'package:apple_notes/services/crud/notes_service.dart';
import 'package:apple_notes/utilities/show_logout_dialog.dart';
import 'package:flutter/material.dart';
//import 'dart:developer' as specialcandy show log;

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  //why late?
  late final NotesService _notesService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  //missing stream

  @override
  void initState() {
    // we need a singleton here (we do not want more than one instance of the class)
    _notesService = NotesService(); //why no new keyword?
    //_notesService.open(); no need (we embedded it in all the db functions, so it will automatically be called thru ensureDbIsOpen())
    super.initState();
  }

  @override
  void dispose() {
    _notesService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main UI'),
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    await AuthService.firebase().signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (route) => false,
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text('Log Out'),
                )
              ];
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _notesService.getOrCreateUser(email: userEmail),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done: //done cuz we're dealing w a FUTURE
              return StreamBuilder(
                stream: _notesService.allNotes,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState
                          .waiting: //waiting cuz we're dealing w a STREAM
                      return const Text('waiitng for all notes...');
                    default:
                      return const CircularProgressIndicator();
                  }
                },
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
