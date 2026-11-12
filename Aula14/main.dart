import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TwitterCloneApp());
}

class TwitterCloneApp extends StatefulWidget {
  const TwitterCloneApp({super.key});

  @override
  State<TwitterCloneApp> createState() => _TwitterCloneAppState();
}

class _TwitterCloneAppState extends State<TwitterCloneApp> {
  static const String baseUrl = 'http://10.0.2.2';
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isDarkMode = false;
  String _userName = 'Usuário';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _carregarSessao();
  }

  Future<void> _carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userName = prefs.getString('userName') ?? 'Usuário';
      _userEmail = prefs.getString('userEmail') ?? '';
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isLoggedIn = false;
      _userName = 'Usuário';
      _userEmail = '';
      _isDarkMode = false;
    });
  }

  Future<void> _loginSuccess(String nome, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', nome);
    await prefs.setString('userEmail', email ?? '');
    await prefs.setBool('isDarkMode', _isDarkMode);
    setState(() {
      _isLoggedIn = true;
      _userName = nome;
      _userEmail = email ?? '';
    });
  }

  Future<void> _toggleTema() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final tema = _isDarkMode ? ThemeData.dark() : ThemeData.light();

    return MaterialApp(
      title: 'Twitter Clone',
      theme: tema.copyWith(
        scaffoldBackgroundColor:
            _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          foregroundColor: _isDarkMode ? Colors.white : Colors.black,
          elevation: 0,
        ),
        cardColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        textTheme: tema.textTheme.apply(
          bodyColor: _isDarkMode ? Colors.white : Colors.black,
          displayColor: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      home: _isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _isLoggedIn
              ? HomeScreen(
                  nome: _userName,
                  email: _userEmail,
                  onLogout: _logout,
                  baseUrl: baseUrl,
                  isDarkMode: _isDarkMode,
                  onToggleTheme: _toggleTema,
                )
              : AuthScreen(
                  baseUrl: baseUrl,
                  onLoginSuccess: _loginSuccess,
                  isDarkMode: _isDarkMode,
                ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final String baseUrl;
  final Future<void> Function(String nome, {String? email}) onLoginSuccess;
  final bool isDarkMode;

  const AuthScreen({
    super.key,
    required this.baseUrl,
    required this.onLoginSuccess,
    required this.isDarkMode,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarCadastro = false;

  Future<void> _submit() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty || (_mostrarCadastro && nome.isEmpty)) {
      _mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _mostrarMensagem('Digite um e-mail válido.');
      return;
    }

    setState(() => _carregando = true);

    try {
      final endpoint = _mostrarCadastro ? 'cadastro.php' : 'login.php';
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/$endpoint'),
        body: {
          if (_mostrarCadastro) 'nome': nome,
          'email': email,
          'senha': senha,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'ok') {
        final nomeUsuario = _mostrarCadastro
            ? (data['nome'] ?? nome)
            : (data['nome'] ?? 'Usuário');

        await widget.onLoginSuccess(nomeUsuario, email: email);
      } else {
        _mostrarMensagem(data['mensagem']?.toString() ?? 'Erro desconhecido.');
      }
    } catch (e) {
      _mostrarMensagem('Erro de conexão: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final surfaceColor =
        widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey[300] : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: const Text('Twitter Clone'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flutter_dash,
                    size: 72,
                    color: widget.isDarkMode
                        ? Colors.lightBlueAccent
                        : Colors.blue),
                const SizedBox(height: 16),
                Text(
                  _mostrarCadastro ? 'Crie sua conta' : 'Entrar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                if (_mostrarCadastro)
                  TextField(
                    controller: _nomeController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: secondaryTextColor),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: secondaryTextColor),
                      filled: true,
                      fillColor: surfaceColor,
                    ),
                  ),
                if (_mostrarCadastro) const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: secondaryTextColor),
                    filled: true,
                    fillColor: surfaceColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: secondaryTextColor),
                    filled: true,
                    fillColor: surfaceColor,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _submit,
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_mostrarCadastro ? 'Cadastrar' : 'Entrar'),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _mostrarCadastro = !_mostrarCadastro;
                      _senhaController.clear();
                      _emailController.clear();
                      _nomeController.clear();
                    });
                  },
                  child: Text(
                    _mostrarCadastro
                        ? 'Já tem conta? Faça login'
                        : 'Não tem conta? Cadastre-se',
                    style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.lightBlueAccent
                            : Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      descricao: json['descricao']?.toString() ?? 'Foto',
      foto: json['foto']?.toString(),
    );
  }
}

class ComentarioPost {
  final String autor;
  final String handle;
  final String texto;

  ComentarioPost({
    required this.autor,
    required this.handle,
    required this.texto,
  });
}

class Postagem {
  final int id;
  final String autor;
  final String handle;
  final String emailAutor;
  final String texto;
  final String? imagemUrl;
  final int curtidas;
  final bool curtidoPorMim;
  final bool isAmigo;
  final List<ComentarioPost> comentarios;

  Postagem({
    required this.id,
    required this.autor,
    required this.handle,
    required this.emailAutor,
    required this.texto,
    this.imagemUrl,
    required this.curtidas,
    required this.curtidoPorMim,
    required this.isAmigo,
    required this.comentarios,
  });

  Postagem copyWith({
    int? id,
    String? autor,
    String? handle,
    String? emailAutor,
    String? texto,
    String? imagemUrl,
    int? curtidas,
    bool? curtidoPorMim,
    bool? isAmigo,
    List<ComentarioPost>? comentarios,
  }) {
    return Postagem(
      id: id ?? this.id,
      autor: autor ?? this.autor,
      handle: handle ?? this.handle,
      emailAutor: emailAutor ?? this.emailAutor,
      texto: texto ?? this.texto,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      curtidas: curtidas ?? this.curtidas,
      curtidoPorMim: curtidoPorMim ?? this.curtidoPorMim,
      isAmigo: isAmigo ?? this.isAmigo,
      comentarios: comentarios ?? this.comentarios,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String nome;
  final String email;
  final Future<void> Function() onLogout;
  final String baseUrl;
  final bool isDarkMode;
  final Future<void> Function() onToggleTheme;

  const HomeScreen({
    super.key,
    required this.nome,
    required this.email,
    required this.onLogout,
    required this.baseUrl,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();
  final Map<int, TextEditingController> _comentarioControllers = {};
  XFile? _fotoSelecionada;
  List<Postagem> _postagens = [];
  List<Map<String, dynamic>> _notificacoes = [];
  bool _carregando = false;
  String? _mensagem;

  Color _corPerfil(String identificador) {
    const palette = [
      Color(0xFF6D4DDB),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFF22C55E),
    ];

    if (identificador.trim().isEmpty) return palette[0];

    final hash = identificador.toLowerCase().codeUnits.fold<int>(
          0,
          (value, codeUnit) => (value + codeUnit) % 1000000,
        );

    return palette[hash % palette.length];
  }

  @override
  void initState() {
    super.initState();
    _carregarFotos();
    _carregarNotificacoes();
  }

  Future<void> _carregarFotos() async {
    try {
      final url = widget.email.isEmpty
          ? '${widget.baseUrl}/busca.php'
          : '${widget.baseUrl}/busca.php?email=${Uri.encodeQueryComponent(widget.email)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return;

      setState(() {
        _postagens = decoded.map((item) {
          final autor = (item['usuario_nome'] ?? widget.nome).toString();
          final comentarios = (item['comentarios'] as List? ?? [])
              .map((comentario) => ComentarioPost(
                    autor: comentario['usuario_nome']?.toString() ?? autor,
                    handle:
                        '@${(comentario['usuario_nome'] ?? autor).toString().replaceAll(' ', '').toLowerCase()}',
                    texto: comentario['texto']?.toString() ?? '',
                  ))
              .toList();

          final totalCurtidas =
              int.tryParse(item['total_curtidas']?.toString() ?? '0') ?? 0;

          final emailAutor = (item['usuario_email'] ?? '').toString().trim();
          final ehAmigo = (item['is_amigo'] ?? false) == true;

          return Postagem(
            id: int.tryParse(item['id']?.toString() ?? '0') ?? 0,
            autor: autor,
            handle: '@${autor.replaceAll(' ', '').toLowerCase()}',
            emailAutor: emailAutor,
            texto: item['descricao']?.toString() ??
                item['texto']?.toString() ??
                '',
            imagemUrl: (item['foto'] ?? '').toString().isEmpty
                ? null
                : '${widget.baseUrl}/${(item['foto'] as String).replaceFirst(RegExp(r"^/+"), '')}',
            curtidas: totalCurtidas,
            curtidoPorMim: false,
            isAmigo: ehAmigo,
            comentarios: comentarios,
          );
        }).toList();
      });
    } catch (_) {
      setState(() {
        _postagens = [];
      });
    }
  }

  Future<void> _escolherFoto(ImageSource source) async {
    final foto = await _picker.pickImage(source: source);
    if (!mounted || foto == null) return;

    setState(() {
      _fotoSelecionada = foto;
      _mensagem = null;
    });
  }

  Future<void> _salvarFoto() async {
    if (_fotoSelecionada == null) {
      setState(() => _mensagem = 'Selecione uma foto antes de publicar.');
      return;
    }

    setState(() {
      _carregando = true;
      _mensagem = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.baseUrl}/salva.php'),
      );

      final descricao = _descricaoController.text.trim();
      request.fields['usuario'] = widget.nome;
      request.fields['email'] = widget.email;
      request.fields['descricao'] =
          descricao.isNotEmpty ? descricao : 'Foto publicada';
      request.fields['txt'] =
          descricao.isNotEmpty ? descricao : 'Foto publicada';
      request.files.add(
        await http.MultipartFile.fromPath('foto', _fotoSelecionada!.path),
      );

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(body.body);
        setState(() {
          _mensagem =
              data['mensagem']?.toString() ?? 'Foto enviada com sucesso!';
          _fotoSelecionada = null;
          _descricaoController.clear();
        });
        await _carregarFotos();
      } else {
        setState(() => _mensagem = 'Erro ao enviar a foto.');
      }
    } catch (e) {
      setState(() => _mensagem = 'Erro de conexão: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _publicarTexto() async {
    final texto = _descricaoController.text.trim();

    if (texto.isEmpty && _fotoSelecionada == null) {
      setState(() =>
          _mensagem = 'Escreva algo ou adicione uma imagem antes de publicar.');
      return;
    }

    if (_fotoSelecionada != null) {
      await _salvarFoto();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/salva.php'),
        body: {
          'usuario': widget.nome,
          'email': widget.email,
          'descricao': texto,
          'txt': texto,
        },
      );

      if (response.statusCode == 200) {
        _descricaoController.clear();
        setState(() => _mensagem = 'Post publicado.');
        await _carregarFotos();
      } else {
        setState(() => _mensagem = 'Erro ao publicar o texto.');
      }
    } catch (e) {
      setState(() => _mensagem = 'Erro de conexão: $e');
    }
  }

  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja sair?'),
        content: const Text('Tem certeza que deseja fazer logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, sair'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.onLogout();
    }
  }

  Future<void> _alternarCurtida(Postagem postagem) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/curtidas.php'),
        body: {
          'post_id': postagem.id.toString(),
          'usuario': widget.nome,
          'email': widget.email,
        },
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final total =
          int.tryParse(data['total_curtidas']?.toString() ?? '0') ?? 0;
      final curtido = data['liked'] == true;

      setState(() {
        final index = _postagens.indexWhere((item) => item.id == postagem.id);
        if (index == -1) return;

        _postagens[index] = _postagens[index].copyWith(
          curtidas: total,
          curtidoPorMim: curtido,
        );
      });
    } catch (_) {}
  }

  Future<void> _adicionarComentario(Postagem postagem) async {
    final controller = _comentarioControllers.putIfAbsent(
      postagem.id,
      () => TextEditingController(),
    );

    final texto = controller.text.trim();
    if (texto.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/comentarios.php'),
        body: {
          'post_id': postagem.id.toString(),
          'usuario': widget.nome,
          'email': widget.email,
          'texto': texto,
        },
      );

      if (response.statusCode == 200) {
        controller.clear();
        await _carregarFotos();
      }
    } catch (_) {}
  }

  Future<void> _carregarNotificacoes() async {
    if (widget.email.isEmpty) {
      setState(() => _notificacoes = []);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${widget.baseUrl}/notificacoes.php?email=${Uri.encodeQueryComponent(widget.email)}'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _notificacoes =
                decoded.map((item) => Map<String, dynamic>.from(item)).toList();
          });
          return;
        }
      }

      setState(() => _notificacoes = []);
    } catch (_) {
      setState(() => _notificacoes = []);
    }
  }

  Future<void> _enviarConviteAmizade(String emailDestino) async {
    final email = emailDestino.trim();
    if (email.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/solicitar_amizade.php'),
        body: {
          'de_nome': widget.nome,
          'de_email': widget.email,
          'para_email': email,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(data['mensagem']?.toString() ?? 'Convite enviado!')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar convite.')),
        );
      }
    }
  }

  Future<void> _aceitarConvite(int notificacaoId, String remetenteEmail) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/aceitar_amizade.php'),
        body: {
          'email': widget.email,
          'remetente_email': remetenteEmail,
          'notificacao_id': notificacaoId.toString(),
        },
      );

      if (response.statusCode == 200) {
        await _carregarNotificacoes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Amizade aceita!')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _abrirDialogoConvite([String? emailPadrao]) async {
    final email = (emailPadrao ?? '').trim();

    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Informe o e-mail da pessoa para enviar o convite.')),
        );
      }
      return;
    }

    await _enviarConviteAmizade(email);
  }

  Future<void> _mostrarNotificacoes() async {
    await _carregarNotificacoes();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificações'),
        content: SizedBox(
          width: 340,
          child: _notificacoes.isEmpty
              ? const Text('Nenhuma notificação no momento.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _notificacoes.map((notificacao) {
                    final mensagem = notificacao['mensagem']?.toString() ??
                        'Pedido de amizade';
                    final remetenteEmail =
                        notificacao['remetente_email']?.toString() ?? '';
                    final notificacaoId =
                        int.tryParse(notificacao['id']?.toString() ?? '0') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(mensagem),
                            ),
                            if (remetenteEmail.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _aceitarConvite(
                                      notificacaoId, remetenteEmail);
                                },
                                child: const Text('Aceitar'),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _comentarioControllers.values) {
      controller.dispose();
    }
    _descricaoController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final cardColor =
        widget.isDarkMode ? const Color(0xFF111827) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey[300] : Colors.grey[700];
    final termoBusca = _buscaController.text.trim().toLowerCase();
    final postagensFiltradas = termoBusca.isEmpty
        ? _postagens
        : _postagens.where((post) {
            final nome = post.autor.toLowerCase();
            final texto = post.texto.toLowerCase();
            return nome.contains(termoBusca) || texto.contains(termoBusca);
          }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Olá, ${widget.nome}',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                tooltip: 'Notificações',
                onPressed: _mostrarNotificacoes,
              ),
              if (_notificacoes.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_notificacoes.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            tooltip: widget.isDarkMode ? 'Tema claro' : 'Tema escuro',
            onPressed: () async => widget.onToggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _confirmarLogout,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'DESLOGAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF6D4DDB),
                        child: Text(
                          widget.nome.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _descricaoController,
                          minLines: 3,
                          maxLines: 5,
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'O que está acontecendo?',
                            hintStyle: TextStyle(color: secondaryTextColor),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fotoSelecionada != null) ...[
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_fotoSelecionada!.path),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _fotoSelecionada = null),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _escolherFoto(ImageSource.gallery),
                        icon: const Icon(Icons.image_outlined),
                        color: const Color(0xFF6D4DDB),
                      ),
                      IconButton(
                        onPressed: () => _escolherFoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        color: const Color(0xFF6D4DDB),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _carregando ? null : _publicarTexto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D4DDB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(_carregando ? 'Enviando...' : 'Postar'),
                      ),
                    ],
                  ),
                  if (_mensagem != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _mensagem!,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Feed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _buscaController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou texto...',
                  hintStyle: TextStyle(color: secondaryTextColor),
                  prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: postagensFiltradas.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma postagem encontrada.',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    )
                  : ListView(
                      children: [
                        for (var i = 0; i < postagensFiltradas.length; i++) ...[
                          if (i > 0 && i % 3 == 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recomendações para você',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Color(0xFF5B7CFA),
                                        child: Text(
                                          'P',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pessoas da sua rede',
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '@suaRede',
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _abrirDialogoConvite(),
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6D4DDB),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                        ),
                                        child: const Text('Convidar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Card(
                            color: cardColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _corPerfil(
                                          '${postagensFiltradas[i].autor}_${postagensFiltradas[i].emailAutor}',
                                        ),
                                        child: Text(
                                          postagensFiltradas[i]
                                              .autor
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              postagensFiltradas[i].autor,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              postagensFiltradas[i].handle,
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (postagensFiltradas[i].isAmigo)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Amigos',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (postagensFiltradas[i]
                                              .emailAutor
                                              .isNotEmpty &&
                                          postagensFiltradas[i]
                                                  .emailAutor
                                                  .toLowerCase() !=
                                              widget.email.toLowerCase())
                                        TextButton(
                                          onPressed: () => _abrirDialogoConvite(
                                            postagensFiltradas[i].emailAutor,
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF6D4DDB),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text('Adicionar'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    postagensFiltradas[i].texto,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (postagensFiltradas[i].imagemUrl !=
                                      null) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor: backgroundColor,
                                              insetPadding:
                                                  const EdgeInsets.all(10),
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                  postagensFiltradas[i]
                                                      .imagemUrl!,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Image.network(
                                          postagensFiltradas[i].imagemUrl!,
                                          width: double.infinity,
                                          height: 260,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Text(
                                                  'Imagem indisponível',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () => _alternarCurtida(
                                              postagensFiltradas[i]),
                                          icon: Icon(
                                            postagensFiltradas[i].curtidoPorMim
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: postagensFiltradas[i]
                                                    .curtidoPorMim
                                                ? Colors.red
                                                : secondaryTextColor,
                                          ),
                                          label: Text(
                                            '${postagensFiltradas[i].curtidas}',
                                            style: TextStyle(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.mode_comment_outlined,
                                            color: secondaryTextColor,
                                          ),
                                          label: Text(
                                            '${postagensFiltradas[i].comentarios.length}',
                                            style: TextStyle(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _comentarioControllers
                                              .putIfAbsent(
                                            postagensFiltradas[i].id,
                                            () => TextEditingController(),
                                          ),
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            hintText: 'Responder...',
                                            hintStyle: TextStyle(
                                              color: secondaryTextColor,
                                            ),
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _adicionarComentario(
                                            postagensFiltradas[i]),
                                        icon: const Icon(Icons.send),
                                        color: const Color(0xFF6D4DDB),
                                      ),
                                    ],
                                  ),
                                  if (postagensFiltradas[i]
                                      .comentarios
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...postagensFiltradas[i].comentarios.map(
                                          (comentario) => Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color: secondaryTextColor,
                                                  fontSize: 13,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${comentario.autor}: ',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: comentario.texto,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
