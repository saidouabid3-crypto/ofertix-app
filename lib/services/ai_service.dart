import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProductModel {
  final String name;
  final String price;
  final String oldPrice;
  final String store;
  final String link;
  final String imageUrl;

  ProductModel({
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.store,
    required this.link,
    required this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      name: json['name'] ?? json['title'] ?? 'No Title',
      price: json['price']?.toString() ?? '0',
      oldPrice: json['old_price']?.toString() ?? '0',
      store: json['store'] ?? 'Unknown',
      link: json['link'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _rotationController;

  List<ProductModel> _results = [];
  bool _isLoading = false;
  double _userRotationOffset = 0.0;

  final String apiUrl = "https://ofertix-api.onrender.com/api/ai-search";

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _performLiveAISearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": query}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _results = responseData
              .map((item) => ProductModel.fromJson(item))
              .toList();
        });
      } else {
        _showErrorSnackBar("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Error de conexión con el servidor backend.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0B0D17),
      body: Stack(
        children: [
          if (_results.isNotEmpty && !_isLoading)
            Center(
              child: Container(
                width: size.width * 0.78,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(size.width)),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.08),
                    width: 2,
                  ),
                ),
              ),
            ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xff161A2A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Icon(
                      Icons.psychology,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "Busca ofertas con IA (ej. iphone)...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Colors.orange,
                      size: 24,
                    ),
                    onPressed: _performLiveAISearch,
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Buscando las mejores ofertas...",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          else if (_results.isNotEmpty)
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _userRotationOffset += details.primaryDelta! * 0.01;
                });
              },
              child: Center(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    double totalAngle =
                        (_rotationController.value * 2 * math.pi) +
                        _userRotationOffset;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.all_inclusive,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),

                        ...List.generate(_results.length, (index) {
                          double offsetAngle =
                              (2 * math.pi / _results.length) * index;
                          double currentAngle = totalAngle + offsetAngle;

                          double radiusX = size.width * 0.38;
                          double radiusY = 80.0;

                          double x = radiusX * math.cos(currentAngle);
                          double y = radiusY * math.sin(currentAngle);

                          double scale = 0.65 + (0.35 * math.sin(currentAngle));
                          double opacity =
                              0.3 + (0.7 * (math.sin(currentAngle) + 1) / 2);

                          final item = _results[index];

                          return Transform.translate(
                            offset: Offset(x, y),
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: _buildOrbitCard(item),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Introduce un producto arriba y pulsa la estrella\npara activar el radar de ofertas con IA.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrbitCard(ProductModel item) {
    return GestureDetector(
      onTap: () async {
        if (item.link.isNotEmpty) {
          final url = Uri.parse(item.link);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: 140,
        height: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xff1C2237),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.store.toLowerCase() == 'aliexpress'
                ? Colors.red.withOpacity(0.6)
                : Colors.orange.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.shopping_bag,
                        color: Colors.grey,
                        size: 35,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag,
                      color: Colors.grey,
                      size: 35,
                    ),
            ),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${item.price}€",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (item.oldPrice != '0') ...[
                  const SizedBox(width: 6),
                  Text(
                    "${item.oldPrice}€",
                    style: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: item.store.toLowerCase() == 'aliexpress'
                    ? Colors.red
                    : Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.store.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
