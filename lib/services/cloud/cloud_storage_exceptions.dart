class CloudStorageException implements Exception {
  const CloudStorageException();
}

// C in Crud
class CouldNotCreateNoteException extends CloudStorageException {}

// R in cRud
class CouldNotGetAllNotesException extends CloudStorageException {}

// U in crUd
class CouldNotUpdateNoteException extends CloudStorageException {}

// D in cruD
class CouldNotDeleteNoteException extends CloudStorageException {}
