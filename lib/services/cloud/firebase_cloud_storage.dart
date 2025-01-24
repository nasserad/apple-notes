import 'package:apple_notes/services/cloud/cloud_note.dart';
import 'package:apple_notes/services/cloud/cloud_storage_constants.dart';
import 'package:apple_notes/services/cloud/cloud_storage_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
  }) async {
    try {
      await notes.doc(documentId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) {
    return notes.snapshots().map((event) => event.docs
        .map((doc) => CloudNote.fromSnapshot(doc))
        .where((note) => note.ownerUserId == ownerUserId));
  }

  Future<Iterable<CloudNote>> getNotes({required ownerUserId}) async {
    try {
      return await notes
          .where(
            ownerUserIdFieldName,
            isEqualTo: ownerUserId,
          )
          .get()
          .then((value) {
        return value.docs.map(
          (doc) {
            return CloudNote.fromSnapshot(doc);
          },
        );
      });
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final document = await notes.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
    final fetchedNote = await document.get();
    return CloudNote(
      documentId: fetchedNote.id,
      ownerUserId: ownerUserId,
      text: '',
    );
  }

  // SINGLETON
  // FIRST: Our singleton instance is first-ever created (basically the lines below) the first time the FirebaseCloudStorage class
  // is referenced (this is how it is in Dart).
  static final FirebaseCloudStorage _sharedInstance =
      FirebaseCloudStorage._sharedInstanceAkaASingleton();

  FirebaseCloudStorage._sharedInstanceAkaASingleton() {}

  // SECOND: So, whenever FirebaseCloudStorage() is called, it'll return the already created
  factory FirebaseCloudStorage() => _sharedInstance;
}
