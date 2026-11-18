import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'models/employee_model.dart';
import 'models/food_model.dart';
import 'models/table_model.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/table_provider.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';

const demoEmployees = <Employee>[
  Employee(
    id: 'employee_demo',
    employeeCode: 'NV001',
    email: 'nv001@bepnha.demo',
    name: 'Nguyễn An',
  ),
];
const demoTables = <RestaurantTable>[
  RestaurantTable(id: 'table_01', name: 'Bàn 01', area: 'Tầng 1'),
  RestaurantTable(id: 'table_02', name: 'Bàn 02', area: 'Tầng 1'),
  RestaurantTable(id: 'table_03', name: 'Bàn 03', area: 'Tầng 1'),
  RestaurantTable(id: 'table_04', name: 'Bàn 04', area: 'Tầng 1'),
  RestaurantTable(id: 'table_05', name: 'Bàn 05', area: 'Tầng 2'),
  RestaurantTable(id: 'table_06', name: 'Bàn 06', area: 'Tầng 2'),
  RestaurantTable(id: 'table_07', name: 'Bàn 07', area: 'Ngoài trời'),
  RestaurantTable(id: 'table_08', name: 'Bàn 08', area: 'Ngoài trời'),
];
const sampleFoods = <Food>[
  Food(
    id: 'food_01',
    name: 'Cơm tấm sườn bì',
    category: 'Món chính',
    price: 55000,
    description: 'Sườn nướng, bì, chả và trứng ốp la',
  ),
  Food(
    id: 'food_02',
    name: 'Mì xào bò',
    category: 'Món chính',
    price: 65000,
    description: 'Mì trứng xào cùng thịt bò và rau củ',
  ),
  Food(
    id: 'food_03',
    name: 'Gỏi cuốn tôm thịt',
    category: 'Khai vị',
    price: 45000,
    description: 'Bốn cuốn gỏi tươi, nước chấm nhà làm',
  ),
  Food(
    id: 'food_04',
    name: 'Trà đào cam sả',
    category: 'Đồ uống',
    price: 35000,
    description: 'Trà đào thơm mát',
  ),
  Food(
    id: 'food_05',
    name: 'Cà phê sữa đá',
    category: 'Đồ uống',
    price: 30000,
    description: 'Cà phê rang xay, sữa đặc',
  ),
  Food(
    id: 'food_06',
    name: 'Nước suối',
    category: 'Đồ uống',
    price: 15000,
    description: 'Nước suối đóng chai',
  ),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(const RestaurantApp());
}

class MyApp extends RestaurantApp {
  const MyApp({super.key});
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});
  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    return MultiProvider(
      providers: [
        Provider.value(value: service),
        ChangeNotifierProvider(create: (_) => AuthProvider(service)),
        ChangeNotifierProvider(create: (_) => TableProvider(service)..load()),
        ChangeNotifierProvider(create: (_) => OrderProvider(service)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'restaurant_pos',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.canvas,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
