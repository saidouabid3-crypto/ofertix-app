import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  final Position? userPosition;
  final List<Product> products;
  final String
  userCountry; // 🌍 زدنا بلاد المستخدم هنا باش الـ AI يعرف فين كاين

  const AIAssistantScreen({
    super.key,
    this.userPosition,
    required this.products,
    this.userCountry = "España", // كقيمة افتراضية
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> chatMessages = [];
  bool loading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      String welcomeText =
          "¡Hola! Soy Ofertix AI 🚀 tu consultor financiero de compras global. Analizo ofertas de redes de afiliados y tiendas locales para darte el máximo ahorro posible. ¿Qué chollo buscas hoy?";
      setState(() {
        chatMessages.add({"role": "assistant", "content": welcomeText});
      });
      _isInitialized = true;
    }
  }

  String _buildSystemPrompt() {
    if (widget.products.isEmpty) {
      return "Eres Ofertix AI, el asistente virtual más astuto en la caza de chollos globales mediante redes de afiliados. Actualmente no hay productos, avisa al usuario con amabilidad.";
    }

    // هنا كنصيفطو الداتا كاملة للـ AI بما فيها الثمن القديم، الجديد، والروابط والبلاد
    final productListString = widget.products
        .take(30)
        .map(
          (p) =>
              "- ${p.name} | Precio Actual: ${p.newPrice}€ | Precio Antiguo: ${p.oldPrice}€ | Tienda: ${p.store} | Categoría: ${p.category}",
        )
        .join("\n");

    return """
Eres Ofertix AI, el asesor financiero de compras y experto en chollos globales número uno del mundo. Tu misión es analizar la lista de productos (provenientes de redes de afiliados como Awin, Impact, Rakuten, etc., y tiendas locales) y guiar al usuario para que compre de forma ultra-inteligente.

📍 País actual del usuario: ${widget.userCountry}
📡 Coordenadas GPS del usuario (si están disponibles): ${widget.userPosition?.latitude}, ${widget.userPosition?.longitude}

Aquí tienes los chollos disponibles AHORA MISMO en nuestra base de datos:
$productListString

Debes seguir estas REGLAS ESTRICTAS para responder de forma perfecta y profesional:

1. **Geo-Targeting Smart Advisor (Asesor Geográfico):** Prioriza y recomienda chollos de tiendas que operen o sean ultra-populares en el país del usuario (${widget.userCountry}). Si hay tiendas locales cerca de sus coordenadas GPS, descácalas frente al envío online largo.
2. **Análisis de Precio Histórico (Caza-Inflación):** Compara siempre el 'Precio Actual' con el 'Precio Antiguo'. Calcula el porcentaje exacto de ahorro real (ej. "¡Te ahorras un 42%!"). Si el descuento es brutal, dile que es un "Mínimo Histórico" y que lo compre ya antes de que se agote. Si el descuento es falso o muy bajo, adviértele con astucia.
3. **Smart Combo (Combinación Inteligente):** Si el usuario busca algo complejo (ej. un portátil, una cámara, ropa), sugiere productos complementarios de la lista que estén en diferentes tiendas para maximizar su ahorro (ej. "Compra el cuerpo de la cámara en Rakuten que está en oferta, pero el objetivo búscalo en AliExpress que sale un 20% más barato").
4. **Enlace de Afiliado Implícito:** Sé muy convincente para que el usuario use tu app para comprar, ya que de ahí sale tu comisión.
5. **Idioma y Estilo:** Responde de forma muy entusiasta, clara, estructurada con viñetas y SIEMPRE en el MISMO IDIOMA en el que te hable el usuario. Sé directo, no inventes productos que no estén en la lista.
""";
  }

  Future<void> searchAI() async {
    final txt = controller.text.trim();
    if (txt.isEmpty || loading) return;

    setState(() {
      chatMessages.add({"role": "user", "content": txt});
      loading = true;
      controller.clear();
    });
    _scrollToBottom();

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama3-8b-8192", // الموديل خدام ناضي وسريع
          "messages": [
            {"role": "system", "content": _buildSystemPrompt()},
            ...chatMessages.map(
              (m) => {"role": m["role"], "content": m["content"]},
            ),
          ],
          "temperature":
              0.6, // هبطناها لـ 0.6 باش الـ AI يكون دقيق وما يبقاش يخربق منتجات من عندو
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply =
            data['choices'][0]['message']['content'] ??
            "No he podido procesar tu solicitud.";

        setState(() {
          chatMessages.add({"role": "assistant", "content": reply});
        });
      } else {
        setState(() {
          chatMessages.add({
            "role": "assistant",
            "content":
                "Error al conectar con Ofertix AI. (Status: ${response.statusCode})",
          });
        });
      }
    } catch (e) {
      setState(() {
        chatMessages.add({
          "role": "assistant",
          "content": "Ocurrió un error inesperado al procesar el chollo.",
        });
      });
    }

    setState(() => loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.dark : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Ofertix AI Radar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final item = chatMessages[index];
                final isMe = item["role"] == "user";
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.orange
                          : (isDark ? AppColors.card : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      item["content"] ?? '',
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dark : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    hintText: "Pregúntale a la IA...",
                    hintStyle: TextStyle(color: AppColors.gray),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => searchAI(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: searchAI,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
