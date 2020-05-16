# OnBehalfofList
App intended for Assisted Living community to allow their residents to use an app for requesting food from cafeteria / items from neighborhood store which can be serviced to their apartment by office admin and help them not to go out for small needs.
### Block diagram
![On Behalf of List block diagram](OnBehalfOfListBlockDiagram.png)
### Technology
- Flutter + Dart
- Firebase; Firestore Native Database
- Brother P-Touch editor for label printer templates
- Flutter plug-ins like Brother Label Printer, QR code creator and scanner
### Shared files
- Label printer P-Touch template (user card, order list)
- Dart files (User: main, cartpage, cartmodel; Admin: main, datamodel) (Flutter Dart file)
- Don't forget to include additional files in flutter project
  - Store logo and refresh icon images
  - google-services file for connecting to firebase
### References
- Firebase Database [Youtube Video](https://www.youtube.com/watch?v=DqJ_KjFzL9I)
- Printing label using P-Touch template [Youtube Video](https://www.youtube.com/watch?v=1EgXb-bHmc0)
- Flutter app development [Youtube Video](https://www.youtube.com/watch?v=I9ceqw5Ny-4&list=PLSzsOkUDsvdtl3Pw48-R8lcK2oYkk40cm); [Free course](https://www.appbrewery.co/p/intro-to-flutter)
- Flutter plug-ins
  - Brother Printer (https://pub.dev/packages/brotherlabelprintdart)
  - QR scanner (https://pub.dev/packages/flutter_barcode_scanner)
  - Firebase and Firestore
