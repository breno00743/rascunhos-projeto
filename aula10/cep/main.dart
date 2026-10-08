import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Editor Markdown',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OrganizaEditorPage(),
    );
  }
}

class OrganizaEditorPage extends StatefulWidget {
  const OrganizaEditorPage({super.key});

  @override
  State<OrganizaEditorPage> createState() => _OrganizaEditorPageState();
}

class _OrganizaEditorPageState extends State<OrganizaEditorPage> {
  final TextEditingController _controller = TextEditingController();
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    lerArquivoMarkdown();
  }

  Future<String> get _pastaDocumentos async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _arquivo async {
    final caminho = await _pastaDocumentos;
    return File('$caminho/organiza.md');
  }

  Future<void> lerArquivoMarkdown() async {
    try {
      final arquivo = await _arquivo;
      if (await arquivo.exists()) {
        final conteudo = await arquivo.readAsString();
        setState(() {
          _controller.text = conteudo;
        });
      }
    } catch (_) {
      setState(() {
        _controller.text = '';
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  Future<void> salvarArquivo() async {
    try {
      final arquivo = await _arquivo;
      await arquivo.writeAsString(_controller.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo organiza.md salvo com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar arquivo: $e')),
      );
    }
  }

  Future<void> apagarArquivo() async {
    try {
      final arquivo = await _arquivo;
      if (await arquivo.exists()) {
        await arquivo.delete();
      }
      setState(() {
        _controller.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo apagado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar arquivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor - organiza.md'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: salvarArquivo,
            tooltip: 'Salvar',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: apagarArquivo,
            tooltip: 'Apagar',
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Escreva seu texto em Markdown abaixo:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: '# Título\n\n- Item 1\n- Item 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: salvarArquivo,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Texto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: apagarArquivo,
                          icon: const Icon(Icons.delete),
                          label: const Text('Apagar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
