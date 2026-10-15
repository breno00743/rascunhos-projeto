import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cadastro de Pets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CadastroPets(),
    );
  }
}

class CadastroPets extends StatefulWidget {
  const CadastroPets({super.key});

  @override
  State<CadastroPets> createState() => _CadastroPetsState();
}

class _CadastroPetsState extends State<CadastroPets>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final nomeSalvar = TextEditingController();
  final idadeSalvar = TextEditingController();

  final idAtualizar = TextEditingController();
  final nomeAtualizar = TextEditingController();
  final idadeAtualizar = TextEditingController();

  final idApagar = TextEditingController();

  late Future<List<Map<String, dynamic>>> petsFuture;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    petsFuture = DatabaseHelper.listarPets();
  }

  void mostrarMensagem(String mensagem) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void carregarPets() {
    setState(() {
      petsFuture = DatabaseHelper.listarPets();
    });
  }

  Future<void> salvarPet() async {
    final nome = nomeSalvar.text.trim();
    final idade = int.tryParse(idadeSalvar.text.trim());

    if (nome.isEmpty || idade == null || idade < 0) {
      mostrarMensagem('Informe o nome e uma idade válida.');
      return;
    }

    try {
      final id = await DatabaseHelper.inserirPet(nome, idade);

      if (!mounted) return;

      nomeSalvar.clear();
      idadeSalvar.clear();
      carregarPets();

      mostrarMensagem('Pet salvo com sucesso! ID: $id');
    } catch (e) {
      if (!mounted) return;
      mostrarMensagem('Erro ao salvar: $e');
    }
  }

  Widget abaListar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: carregarPets,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar lista'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: petsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao listar: ${snapshot.error}'),
                );
              }

              final pets = snapshot.data ?? [];

              if (pets.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum pet cadastrado.',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${pet['id']}'),
                      ),
                      title: Text('${pet['nome']}'),
                      subtitle: Text('Idade: ${pet['idade']} anos'),
                      trailing: const Icon(Icons.pets),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> atualizarPet() async {
    final id = int.tryParse(idAtualizar.text.trim());
    final nome = nomeAtualizar.text.trim();
    final idade = int.tryParse(idadeAtualizar.text.trim());

    if (id == null || id <= 0 || nome.isEmpty || idade == null || idade < 0) {
      mostrarMensagem('Preencha todos os campos corretamente.');
      return;
    }

    try {
      final quantidade = await DatabaseHelper.atualizarPet(
        id,
        nome,
        idade,
      );

      if (!mounted) return;

      if (quantidade == 0) {
        mostrarMensagem('Nenhum pet encontrado com esse ID.');
      } else {
        idAtualizar.clear();
        nomeAtualizar.clear();
        idadeAtualizar.clear();

        carregarPets();
        mostrarMensagem('Pet atualizado com sucesso!');
      }
    } catch (e) {
      if (!mounted) return;
      mostrarMensagem('Erro ao atualizar: $e');
    }
  }

  Future<void> apagarPet() async {
    final id = int.tryParse(idApagar.text.trim());

    if (id == null || id <= 0) {
      mostrarMensagem('Informe um ID válido.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar pet'),
        content: Text('Deseja realmente apagar o pet de ID $id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final quantidade = await DatabaseHelper.apagarPet(id);

      if (!mounted) return;

      if (quantidade == 0) {
        mostrarMensagem('Nenhum pet encontrado com esse ID.');
      } else {
        idApagar.clear();
        carregarPets();
        mostrarMensagem('Pet apagado com sucesso!');
      }
    } catch (e) {
      if (!mounted) return;
      mostrarMensagem('Erro ao apagar: $e');
    }
  }

  Widget campo({
    required String label,
    required TextEditingController controller,
    bool numerico = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: numerico ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget botao({
    required String texto,
    required IconData icone,
    required VoidCallback acao,
    Color? cor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: acao,
        icon: Icon(icone),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: cor == null ? null : Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    nomeSalvar.dispose();
    idadeSalvar.dispose();

    idAtualizar.dispose();
    nomeAtualizar.dispose();
    idadeAtualizar.dispose();

    idApagar.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cadastro de Pets'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.save), text: 'Salvar'),
              Tab(icon: Icon(Icons.list), text: 'Listar'),
              Tab(icon: Icon(Icons.edit), text: 'Atualizar'),
              Tab(icon: Icon(Icons.delete), text: 'Apagar'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Cadastrar pet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                campo(
                  label: 'Nome do pet',
                  controller: nomeSalvar,
                ),
                campo(
                  label: 'Idade do pet',
                  controller: idadeSalvar,
                  numerico: true,
                ),
                botao(
                  texto: 'Salvar pet',
                  icone: Icons.save,
                  cor: Colors.green,
                  acao: salvarPet,
                ),
              ],
            ),
            abaListar(),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Atualizar pet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                campo(
                  label: 'ID do pet',
                  controller: idAtualizar,
                  numerico: true,
                ),
                campo(
                  label: 'Novo nome',
                  controller: nomeAtualizar,
                ),
                campo(
                  label: 'Nova idade',
                  controller: idadeAtualizar,
                  numerico: true,
                ),
                botao(
                  texto: 'Atualizar pet',
                  icone: Icons.edit,
                  cor: Colors.orange,
                  acao: atualizarPet,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Consulte a aba Listar para encontrar o ID.',
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Apagar pet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 65,
                ),
                campo(
                  label: 'ID do pet',
                  controller: idApagar,
                  numerico: true,
                ),
                botao(
                  texto: 'Apagar pet',
                  icone: Icons.delete,
                  cor: Colors.red,
                  acao: apagarPet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
