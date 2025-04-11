import 'package:flutter/material.dart';
// import '../utils/theme.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({Key? key}) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  // Definir a cor primária localmente
  final Color primaryColor = Color(0xFF00CCBB);
  
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_pageListener);
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
  }

  void _pageListener() {
    if (_pageController.hasClients && _pageController.page != null) {
      int newPage = _pageController.page!.round();
      if (_currentPage != newPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ajustar a altura com base no tamanho da tela
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 600 && screenWidth <= 1000;
    
    return Container(
      width: double.infinity,
      height: isDesktop ? 600 : (isTablet ? 500 : 400),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A4F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A5F),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildImageCardWithNetwork('assets/images/image1.jpeg', 
                      'https://images.unsplash.com/photo-1582719471384-894fbb16e074', 
                      'Registre seus plantões facilmente'),
                    _buildImageCardWithNetwork('assets/images/image2.jpeg', 
                      'https://images.unsplash.com/photo-1579621970590-9d624316904b', 
                      'Acompanhe suas finanças em tempo real'),
                    _buildImageCardWithNetwork('assets/images/image3.jpeg', 
                      'https://images.unsplash.com/photo-1579621970795-87facc2f976d', 
                      'Relatórios detalhados para melhor gestão'),
                  ],
                ),
                // Botões de navegação
                Positioned(
                  left: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _currentPage < 2 ? () => _goToPage(_currentPage + 1) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Indicadores
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return GestureDetector(
                onTap: () => _goToPage(index),
                child: Container(
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? primaryColor 
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Widget para tentar carregar imagens locais primeiro, e usar uma imagem da rede como fallback
  Widget _buildImageCardWithNetwork(String localPath, String networkPath, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    localPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Se a imagem local falhar, tenta carregar da web
                      return Image.network(
                        networkPath,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Se ambas as imagens falharem, mostra um placeholder
                          return Container(
                            color: const Color(0xFF2A2A5F),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Imagem em breve',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A5F),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Center(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 