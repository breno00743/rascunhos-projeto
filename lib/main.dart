import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// ============================================================
// APLICATIVO
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fotos da Wikipédia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const Inicio(),
    );
  }
}

// ============================================================
// CLASSE FOTO
// ============================================================

class Foto {
  final String titulo;
  final String url;

  Foto({
    required this.titulo,
    required this.url,
  });
}

// ============================================================
// TELA PRINCIPAL
// ============================================================

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with SingleTickerProviderStateMixin {
  late TabController tabController;

  // Lista de fotos disponíveis
  final List<Foto> fotos = [];

  // Lista de fotos aceitas
  final List<Foto> aceitas = [];

  // Foto que está sendo avaliada
  Foto? fotoSelecionada;

  bool carregando = true;
  String mensagemErro = '';

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 3,
      vsync: this,
    );

    carregarFotos();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUSCAR FOTOS NA WIKIPÉDIA
  // ==========================================================

  Future<void> carregarFotos() async {
    setState(() {
      carregando = true;
      mensagemErro = '';
    });

    try {
      final nomes = [
        'Gato',
        'Cachorro',
        'Leão',
        'Elefante',
        'Pinguim',
        'Girafa',
        'Tigre',
        'Cavalo',
        'Panda',
      ];

      final titulos = nomes.join('|');

      final url = Uri.parse(
        'https://pt.wikipedia.org/w/api.php'
        '?action=query'
        '&format=json'
        '&prop=pageimages'
        '&piprop=thumbnail'
        '&pithumbsize=400'
        '&titles=${Uri.encodeComponent(titulos)}'
        '&origin=*',
      );

      final resposta = await http.get(url);

      if (resposta.statusCode != 200) {
        throw Exception('Erro na conexão.');
      }

      final dados = jsonDecode(resposta.body);

      final paginas = dados['query']['pages'] as Map<String, dynamic>;

      final listaTemporaria = <Foto>[];

      for (final pagina in paginas.values) {
        final thumbnail = pagina['thumbnail'];

        if (thumbnail != null) {
          final titulo = pagina['title'];
          final imagem = thumbnail['source'];

          listaTemporaria.add(
            Foto(
              titulo: titulo,
              url: imagem,
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        fotos.clear();
        fotos.addAll(listaTemporaria);
        carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
        mensagemErro = 'Erro ao carregar as imagens.';
      });
    }
  }

  // ==========================================================
  // SELECIONAR FOTO
  // ==========================================================

  void selecionarFoto(Foto foto) {
    setState(() {
      fotoSelecionada = foto;
    });

    tabController.animateTo(1);
  }

  // ==========================================================
  // ACEITAR
  // ==========================================================

  void aceitarFoto() {
    if (fotoSelecionada == null) {
      return;
    }

    final foto = fotoSelecionada!;

    setState(() {
      // Adiciona na lista de aceitas
      if (!aceitas.contains(foto)) {
        aceitas.add(foto);
      }

      // Remove da galeria
      fotos.remove(foto);

      // Limpa a seleção
      fotoSelecionada = null;
    });

    // Volta para a galeria
    tabController.animateTo(0);
  }

  // ==========================================================
  // RECUSAR
  // ==========================================================

  void recusarFoto() {
    if (fotoSelecionada == null) {
      return;
    }

    final foto = fotoSelecionada!;

    setState(() {
      // Remove da galeria
      fotos.remove(foto);

      // Limpa a seleção
      fotoSelecionada = null;
    });

    // Volta para a galeria
    tabController.animateTo(0);
  }

  // ==========================================================
  // BUILD PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos da Wikipédia'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.photo_library),
              text: 'Galeria',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Avaliar',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Aceitas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          telaGaleria(),
          telaAvaliacao(),
          telaAceitas(),
        ],
      ),
    );
  }

  // ==========================================================
  // ABA 1 - GALERIA
  // ==========================================================

  Widget telaGaleria() {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (mensagemErro.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mensagemErro,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: carregarFotos,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (fotos.isEmpty) {
      return const Center(
        child: Text(
          'Todas as fotos foram avaliadas!',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),

      // 3 imagens por linha
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),

      // IMPORTANTE:
      // usamos o tamanho atual da lista
      itemCount: fotos.length,

      itemBuilder: (context, index) {
        // IMPORTANTE:
        // index sempre estará entre 0 e fotos.length - 1
        final foto = fotos[index];

        return GestureDetector(
          onTap: () {
            selecionarFoto(foto);
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    foto.url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    foto.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // ABA 2 - AVALIAR
  // ==========================================================

  Widget telaAvaliacao() {
    // Nenhuma foto selecionada
    if (fotoSelecionada == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Clique em uma foto na Galeria',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    final foto = fotoSelecionada!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              foto.titulo,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.network(
              foto.url,
              height: 350,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 100,
                );
              },
            ),
            const SizedBox(height: 25),
            const Text(
              'Você aceita esta imagem?',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // BOTÃO RECUSAR
                ElevatedButton.icon(
                  onPressed: recusarFoto,
                  icon: const Icon(
                    Icons.close,
                  ),
                  label: const Text(
                    'Recusar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),

                // BOTÃO ACEITAR
                ElevatedButton.icon(
                  onPressed: aceitarFoto,
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text(
                    'Aceitar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ABA 3 - ACEITAS
  // ==========================================================

  Widget telaAceitas() {
    if (aceitas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Nenhuma foto aceita ainda.',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.80,
      ),

      // IMPORTANTE:
      // usamos o tamanho atual da lista
      itemCount: aceitas.length,

      itemBuilder: (context, index) {
        // index nunca passa de aceitas.length - 1
        final foto = aceitas[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  foto.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        foto.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
