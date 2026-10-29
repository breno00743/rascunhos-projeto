import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tabuada',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const TabuadaPage(),
    );
  }
}

class TabuadaPage extends StatefulWidget {
  const TabuadaPage({super.key});

  @override
  State<TabuadaPage> createState() => _TabuadaPageState();
}

class _TabuadaPageState extends State<TabuadaPage> {
  final TextEditingController respostaController = TextEditingController();

  int fator = 1;
  int multiplicador = 1;
  int acertos = 0;

  final int totalOperacoes = 5;

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarProgresso();
  }

  // Carrega o progresso salvo.
  Future<void> carregarProgresso() async {
    final prefs = await SharedPreferences.getInstance();

    final fatorSalvo = prefs.getInt('fator') ?? 1;
    final multiplicadorSalvo = prefs.getInt('multiplicador') ?? 1;
    final acertosSalvos = prefs.getInt('acertos') ?? 0;

    if (!mounted) return;

    setState(() {
      fator = fatorSalvo.clamp(1, 10);
      multiplicador = multiplicadorSalvo.clamp(1, totalOperacoes);
      acertos = acertosSalvos.clamp(0, totalOperacoes);
      carregando = false;
    });
  }

  // Salva o progresso atual.
  Future<void> salvarProgresso() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('fator', fator);
    await prefs.setInt('multiplicador', multiplicador);
    await prefs.setInt('acertos', acertos);
  }

  // Adiciona o número pressionado à resposta.
  void digitarNumero(String numero) {
    if (carregando) return;

    setState(() {
      respostaController.text += numero;
    });
  }

  // Apaga o último dígito.
  void apagarNumero() {
    if (carregando || respostaController.text.isEmpty) {
      return;
    }

    setState(() {
      respostaController.text = respostaController.text.substring(
        0,
        respostaController.text.length - 1,
      );
    });
  }

  // Limpa toda a resposta.
  void limparResposta() {
    if (carregando) return;

    setState(() {
      respostaController.clear();
    });
  }

  // Verifica se a resposta está correta.
  void verificarResposta() {
    if (carregando) return;

    final int? resposta = int.tryParse(respostaController.text);

    if (resposta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma resposta válida!'),
        ),
      );
      return;
    }

    final int resultado = fator * multiplicador;

    if (resposta == resultado) {
      limparResposta();

      if (multiplicador < totalOperacoes) {
        setState(() {
          acertos++;
          multiplicador++;
        });

        salvarProgresso();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acertou!!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        setState(() {
          acertos = totalOperacoes;
        });

        mudarFator(
          'Parabéns! Você acertou todas!',
        );
      }
    } else {
      limparResposta();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Errou, clique aqui para continuar.',
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'CONTINUAR',
            textColor: Colors.white,
            onPressed: () {
              mudarFator(
                'Vamos tentar outro fator!',
              );
            },
          ),
        ),
      );
    }
  }

  // Muda a tabuada e salva o novo estado.
  Future<void> mudarFator(String mensagem) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      fator++;

      if (fator > 10) {
        fator = 1;
      }

      multiplicador = 1;
      acertos = 0;
      respostaController.clear();
    });

    await salvarProgresso();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    respostaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exercício de Multiplicação',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pergunta da tabuada.
                    Text(
                      'Quanto é $fator × $multiplicador?',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Fator atual: $fator',
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Operação $multiplicador de '
                      '$totalOperacoes',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Barra de progresso.
                    LinearProgressIndicator(
                      value: acertos / totalOperacoes,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    const SizedBox(height: 8),

                    // Porcentagem concluída.
                    Text(
                      '${(acertos / totalOperacoes * 100).toInt()}% concluído',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Mostra a resposta digitada.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue.withOpacity(0.05),
                      ),
                      child: Text(
                        respostaController.text.isEmpty
                            ? 'Digite o resultado'
                            : respostaController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Teclado numérico.
                    SizedBox(
                      width: 300,
                      child: Column(
                        children: [
                          // Botões de 1 a 9.
                          for (int linha = 0; linha < 3; linha++)
                            Row(
                              children: [
                                for (int coluna = 1; coluna <= 3; coluna++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: SizedBox(
                                        height: 60,
                                        child: ElevatedButton(
                                          onPressed: () => digitarNumero(
                                            '${linha * 3 + coluna}',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '${linha * 3 + coluna}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                          // Botões apagar, zero e limpar.
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: apagarNumero,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Icon(
                                        Icons.backspace_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: () => digitarNumero('0'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        '0',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: limparResposta,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botão para verificar a resposta.
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: verificarResposta,
                        icon: const Icon(
                          Icons.check_circle,
                        ),
                        label: const Text(
                          'Verificar resposta',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
