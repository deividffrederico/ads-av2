# Caminho do script
SCRIPT=./run.sh
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
