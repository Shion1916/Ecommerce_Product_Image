import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

const Color RichBlack = Color(0xFF1D1F24);
const Color OffWhite = Color(0xFFF8F4F0);
const Color Charcoal = Color(0xFF73787C);
const Color Gray = Color(0xFFC5C6C7);
const Color PaleBlue = Color(0xFFD7E5F0);
const Color Beige = Color(0xFFC9AD93);
const Color Taupe = Color(0xFF554940);
const Color SoftGreen = Color(0xFF879A77);

//    5

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  final cartProvider = CartProvider();
  cartProvider.initializeAuthListener();
  runApp(
    ChangeNotifierProvider.value(
      value: cartProvider,
      child: const MyApp(),
    ),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: SoftGreen,
          brightness: Brightness.light,
          primary: SoftGreen,
          onPrimary: Colors.white,
          secondary: SoftGreen,
          background: Beige,
        ),
        useMaterial3: true,

        scaffoldBackgroundColor: Beige,

        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PaleBlue,
            foregroundColor: RichBlack,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          labelStyle: TextStyle(color: RichBlack.withOpacity(0.8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SoftGreen, width: 2.0),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Taupe,
          foregroundColor: OffWhite,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

