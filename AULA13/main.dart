import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fotos do Exercício',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const FotosAppScreen(),
    );
  }
}

class FotoItem {
  final int id;
  final String descricao;
  final String? foto;

  FotoItem({required this.id, required this.descricao, this.foto});

  factory FotoItem.fromJson(Map<String, dynamic> json) {
    return FotoItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      descricao:
          json['descricao']?.toString() ?? json['texto']?.toString() ?? 'Foto',
      foto: json['foto']?.toString(),
    );
  }
}

class FotosAppScreen extends StatefulWidget {
  const FotosAppScreen({super.key});

  @override
  State<FotosAppScreen> createState() => _FotosAppScreenState();
}

class _FotosAppScreenState extends State<FotosAppScreen> {
  static const String baseUrl = 'http://10.0.2.2/hp';

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descricaoController = TextEditingController();
  XFile? _fotoSelecionada;
  List<FotoItem> _fotos = [];
  int _indiceAtual = 0;
  String? _mensagem;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarGaleria();
  }

  Future<void> _carregarGaleria() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/busca.php'));
      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return;
      }

      final fotos = decoded
          .map((item) => FotoItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      setState(() {
        _fotos = fotos;
        if (_fotos.isNotEmpty && _indiceAtual >= _fotos.length) {
          _indiceAtual = _fotos.length - 1;
        }
      });
    } catch (_) {
      setState(() {
        _fotos = [];
      });
    }
  }

  Future<void> _escolherFoto(ImageSource source) async {
    final foto = await _picker.pickImage(source: source);
    if (foto != null) {
      setState(() {
        _fotoSelecionada = foto;
      });
    }
  }

  Future<void> _salvarFoto() async {
    if (_fotoSelecionada == null) {
      setState(() {
        _mensagem = 'Selecione uma foto antes de salvar.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _mensagem = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/salva.php'),
      );

      final descricao = _descricaoController.text.trim();
      request.fields['descricao'] =
          descricao.isNotEmpty ? descricao : 'Foto enviada';
      request.fields['txt'] = descricao.isNotEmpty ? descricao : 'Foto enviada';
      request.files.add(
        await http.MultipartFile.fromPath('foto', _fotoSelecionada!.path),
      );

      final resposta = await request.send();
      final body = await http.Response.fromStream(resposta);

      if (resposta.statusCode == 200) {
        final decoded = jsonDecode(body.body);
        setState(() {
          _mensagem = decoded['mensagem']?.toString() ?? 'Foto salva!';
          _fotoSelecionada = null;
          _descricaoController.clear();
        });
        await _carregarGaleria();
      } else {
        setState(() {
          _mensagem = 'Erro ao enviar. Código: ${resposta.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _mensagem = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _proximaFoto() {
    if (_fotos.isEmpty) return;
    setState(() {
      _indiceAtual = (_indiceAtual + 1) % _fotos.length;
    });
  }

  void _fotoAnterior() {
    if (_fotos.isEmpty) return;
    setState(() {
      _indiceAtual = (_indiceAtual - 1 + _fotos.length) % _fotos.length;
    });
  }

  Widget _buildEnviarTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enviar foto',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descricaoController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _fotoSelecionada == null
                ? const Center(
                    child: Text('Nenhuma foto selecionada.'),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_fotoSelecionada!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _carregando ? null : _salvarFoto,
            icon: const Icon(Icons.cloud_upload),
            label: Text(_carregando ? 'Enviando...' : 'Salvar no site'),
          ),
          if (_mensagem != null) ...[
            const SizedBox(height: 12),
            Text(
              _mensagem!,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGaleriaTab() {
    if (_fotos.isEmpty) {
      return const Center(
        child: Text('Ainda não há fotos salvas.'),
      );
    }

    final foto = _fotos[_indiceAtual];
    final imageUrl = foto.foto == null || foto.foto!.trim().isEmpty
        ? null
        : '$baseUrl/${foto.foto!.replaceFirst(RegExp(r"^/+"), '')}';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Galeria',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Foto ${_indiceAtual + 1} de ${_fotos.length}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: imageUrl == null
                        ? const Center(child: Text('Imagem indisponível'))
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Erro ao carregar imagem'),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      foto.descricao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _fotoAnterior,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _proximaFoto,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Próxima'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exercício Final'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Enviar foto'),
              Tab(text: 'Galeria'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEnviarTab(),
            _buildGaleriaTab(),
          ],
        ),
      ),
    );
  }
}
