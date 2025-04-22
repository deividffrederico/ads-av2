#import "@preview/klaro-ifsc-sj:0.1.0": report
#import "@preview/codelst:2.0.2": sourcecode
#show heading: set block(below: 1.5em)
#show par: set block(spacing: 1.5em)
#set text(font: "Arial", size: 12pt)
#set text(lang: "pt")
#set page(
  footer: "Engenharia de Telecomunicações - IFSC-SJ",
)

#show: doc => report(
  title: "MiniProjeto - Medição Ativa em Redes com o Iperf",
  subtitle: "Avaliação de Desempenho de Sistemas",
  authors: ("Arthur Cadore Matuella Barcella",),
  date: "11 de Abril de 2025",
  doc,
)

= Introdução

Este relatório tem como objetivo apresentar o desenvolvimento e os resultados obtidos no mini projeto de medição ativa em redes utilizando o Iperf. 

== Especificação de cenário

- Uso da ferramenta iperf;
- Uso da ferramenta imunes;
- Automação de tarefas via scritpt shell e comandos do simulador imunes;
- Conceitos de intervalo de confiança e
- Projeto fatorial 2kr e boas práticas de projeto de experimentos.

== Topologia: 

A topologia utilizada no experimento foi a seguinte:

#figure(
  figure(
    rect(image("./pictures/scenario.png")),
    numbering: none,
    caption: []
  ),
  caption: figure.caption([Elaborada pelo Autor], position: top)
)

== Objetivo

Avaliar, por meio de medição ativa com iperf, como a vazão de uma conexão TCP é afetada por dois fatores:

- O número de fluxos TCP paralelos (parâmetro -P no cliente);

- O retardo de rede, emulado com o comando vlink.

Além disso, verificar se há interação entre os fatores na determinação da vazão.

=== Fatores e níveis

Os fatores e níveis utilizados no experimento foram:

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left }
  )
)
#align(center)[
#rect(table(
  columns: 3,
  table.header(
    [Fator],
    [Nivel Baixo],
    [Nivel Alto],
  ),
  [A: Paralelismo TCP (-P)],
  [1 fluxo], [4 fluxo],
  [B: Retardo de rede (RTT)],
  [10 ms (ida ⇒ RTT20ms)], [100 ms (ida ⇒ RTT200ms)],
))]

=== Metrica avaliada

- Vazão total (em Mbps), somando todos os fluxos, medida no cliente ao final da execução.

=== Execuções: 

Os ciclos de execução utilizados foram os seguintes: 

#align(center)[
#rect(table(
  columns: 4,
  table.header(
    [Execução],
    [Fluxos (-P)],
    [Delay (ms)],
    [Repetições],
  ),
  [1],
  [1], [10],[8],
  [2],
  [1], [100],[8],
  [3],
  [4], [10],[8],
  [4],
  [4], [100],[8],

))]


= Desenvolvimento 

Abaixo está a descrição do desenvolvimento do experimento, incluindo a configuração do ambiente, o script utilizado para automatizar a execução e o Makefile utilizado para facilitar a execução de múltiplas iterações.

== Script Shell

O script shell desenvolvido para automatizar a execução do experimento foi o seguinte. O script é executado em três passsos: 

- Primeiramente, ele inicia o simulador IMUNES em background, utilizando o cenário desejado.

- Em seguida, configura os links de acordo com os parâmetros desejados, utilizando o comando vlink.

- Por fim, inicia o servidor iperf nas máquinas desejadas e executa o cliente iperf, coletando os resultados.

#sourcecode[```sh
#!/bin/bash

TOPOLOGY_FILE=scenario.imn
BANDWIDTH=100000000
# SCENARIO_ID=i2002
# DELAY=10000
# FLUXES=1

# Create a log directory if it doesn't exist
mkdir -p ./log

echo "========================================================="
echo "Starting IMUNES simulation with scenario ID: $SCENARIO_ID"

# Run IMUNES in background and redirect all output to log
sudo imunes -b -e $SCENARIO_ID $TOPOLOGY_FILE > /dev/null
sleep 2

echo "========================================================="
echo "Simulation started, applying commands..."

# Link configurations
sudo vlink -bw $BANDWIDTH -dly $DELAY router1:pc1@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router1:pc3@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router2:pc2@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router2:pc4@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router2:router1@$SCENARIO_ID > /dev/null
sleep 2

# Check status (optional)
sudo vlink -s router1:pc1@$SCENARIO_ID
sudo vlink -s router1:pc3@$SCENARIO_ID
sudo vlink -s router2:pc2@$SCENARIO_ID
sudo vlink -s router2:pc4@$SCENARIO_ID
sudo vlink -s router2:router1@$SCENARIO_ID
sleep 2

# Start iperf servers
sudo himage pc2@$SCENARIO_ID iperf -s &> /dev/null &
sudo himage pc4@$SCENARIO_ID iperf -s &> /dev/null &

# Generate background UDP traffic (mute output)
sudo himage pc1@$SCENARIO_ID iperf -c 10.0.3.20 -u -t 100000 -b 10M &> /dev/null &
sleep 2


# Run TCP test (this is the one you want to see)
echo "========================================================="
echo "Running TCP test between PC3 and PC4..."
sudo himage pc3@$SCENARIO_ID iperf -c 10.0.4.20 -n 100M -P $FLUXES -i 1 

# Stop simulation
echo "========================================================="
echo "Stopping IMUNES simulation with scenario ID: $SCENARIO_ID"
sudo imunes -b -e $SCENARIO_ID > /dev/null
echo "========================================================="
echo "Simulation stopped"
```]

Para executa-lo, 3 variáveis são necessárias junto com o script: 

- SCENARIO_ID: ID do cenário a ser utilizado.
- DELAY: Retardo de rede a ser utilizado.
- FLUXES: Número de fluxos TCP a serem utilizados.

Essas variáveis podem ser configuradas previamente no OS, ou então descomentar as linhas 3, 4 e 5 do script e definir os valores desejados.

== Script Makefile

O script make utilizado para automatizar a execução do experimento foi o seguinte. O objetivo da utilização de um Makefile é passar as variáveis definidas no script shell como parâmetro e então executar o script shell com os parâmetros desejados.

#sourcecode[```make
# Caminho do script shell
SCRIPT=./run.sh

# Caminho do diretório de log
LOGDIR=./log

# Targets
all: exec1 exec2 exec3 exec4

exec1:
	@echo "ETAPA1: Executando com DELAY=10000 FLUXES=1" | tee -a $(LOGDIR)/output.log
	@for i in $$(seq 1000 1008); do \
		echo ">> Execução $$i da ETAPA1" | tee -a $(LOGDIR)/output.log; \
		DELAY=10000 FLUXES=1 SCENARIO_ID=$$i $(SCRIPT) 2>&1 | tee -a $(LOGDIR)/output.log; \
	done

exec2:
	@echo "ETAPA2: Executando com DELAY=100000 FLUXES=1" | tee -a $(LOGDIR)/output.log
	@for i in $$(seq 1000 1008); do \
		echo ">> Execução $$i da ETAPA2" | tee -a $(LOGDIR)/output.log; \
		DELAY=100000 FLUXES=1 SCENARIO_ID=$$i $(SCRIPT) 2>&1 | tee -a $(LOGDIR)/output.log; \
	done

exec3:
	@echo "ETAPA3: Executando com DELAY=10000 FLUXES=4" | tee -a $(LOGDIR)/output.log
	@for i in $$(seq 1000 1008); do \
		echo ">> Execução $$i da ETAPA3" | tee -a $(LOGDIR)/output.log; \
		DELAY=10000 FLUXES=4 SCENARIO_ID=$$i $(SCRIPT) 2>&1 | tee -a $(LOGDIR)/output.log; \
	done

exec4:
	@echo "ETAPA4: Executando com DELAY=100000 FLUXES=4" | tee -a $(LOGDIR)/output.log
	@for i in $$(seq 1000 1008); do \
		echo ">> Execução $$i da ETAPA4" | tee -a $(LOGDIR)/output.log; \
		DELAY=100000 FLUXES=4 SCENARIO_ID=$$i $(SCRIPT) 2>&1 | tee -a $(LOGDIR)/output.log; \
	done

.PHONY: all exec1 exec2 exec3 exec4
```]

== Resultados obtidos


Parar extrair apenas os logs de interesse, o seguinte comando pode ser utilizado:

#sourcecode[```bash
# comando de filtragem:
awk '/^Running TCP test between/,/^=+/' seu_arquivo_de_log.txt > filtrado.txt
```]


= Conclusão 

= Referências
