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
  // Because we deferred the initialization to initState() to ensure proper runtime logic
  // where we (for example) do not initialize a notesService instance b4 user authentication,
  // or some other functionality (that the service is dependent on) is ready/initialized.
  late final NotesService _notesService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _notesService =
        NotesService(); //We're able to initialize here becuz of the LATE keyword.
    //_notesService.open(); no need (we embedded it in all the db functions, so it will automatically be called thru ensureDbIsOpen())
    super.initState();
  }

  @override
  void dispose() async {
    await _notesService.deleteAllNotes();
    _notesService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Notes'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(newNoteRoute);
              // We didnt use push namedAndRemoveUntil becuz we want the user
              // to be able to come back to this view (notes view), whenever
              // they want.
            },
            icon: const Icon(Icons.add),
          ),
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
                    case ConnectionState
                          .active: //Here we implemented a 'FALLTHRU' (we need active cuz we need the logic to be here when state is active (stream returned one value but is not yet done))
                      if (snapshot.hasData) {
                        final allNotes = snapshot.data as List<DatabaseNote>;
                        print('2.');
                        print(allNotes);
                        return const Text('Got all notes.');
                      } else {
                        print('1. snapshot didnt have data');
                        return const CircularProgressIndicator();
                      }
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
