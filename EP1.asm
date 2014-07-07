.text
.globl main
main:
	jal get_file_name
	add $a0, $v0, $zero
	
	jal read_file
	jal convert_to_int_array
	
	jal type_of_sort
	
	add $a0, $s2, $zero # base do array de inteiros
	add $a1, $s4, $zero # numero de elementos no array de inteiros
	add $a3, $v0, $zero #pega o sort escolhido pelo usuário
	
	jal ordena
	jal convert_to_byte_array
	jal write_file
	
	j exit
	
###########################################################################################

get_file_name:
# Retorna em $v0 o endereço para o nome do arquivo. Usa do dialog para input
	li $v0, 54 		# carrega chamada de sistema para mostrar um dialog para input de string
	la $a0, input_file_name_msg # carrega a mensagem a ser mostrada no dialog
	la $a1, file_name 	# carrega o local onde será armazenado o input do usuário
	lw $a2, min_size 	# carrega o número de bytes que serão lidos
	syscall 		# coloca em $a1 o valor do status:
				# (0: OK status. -2: Cancel. -3: input.vazio. -4: tamanho do input maior)
	
	bne $a1, $zero, exit_error 	# se o status foi diferente de 0, sai do programa
	
	la  $v0, file_name		# carrega o nome do arquivo em $v0, para retorno

# inicializando contador do loop para limpar o nome do arquivo e 
# tirar o caractere que determina o final da string que não serve quando for usar para abrir o arquivo	
   	li  $t0, 0       	
   	lw  $t1, min_size	      	# inicializando o final do loop
    
remove_line_feed_loop:
	beq $t0, $t1, back_stack	# verifica se o loop chegou ao final
    lb  $t3, file_name($t0) 		# pega o byte de determinada posição do nome do arquivo
    bne $t3, 10, cont_remove_line_feed_loop # verifica se esse byte contém o caracter 10 (linefeed)
    sb  $zero, file_name($t0) 	 	# se for igual ao caracter 10, substitui ele por zero
	j   back_stack

cont_remove_line_feed_loop:
    addi $t0, $t0, 1 			# incrementa o contador
	j remove_line_feed_loop
	
###############################################################################################################################

read_file:
# Abre pra leitura o arquivo de entrada especificado em $a0
	li   $v0, 13        	# carrega chamada de sistema para abertura de arquivo
	# é esperado que $a0 contenha o endereço para o nome do arquivo
	li   $a1, 0     	# parâmetro para abrir para leitura (0: leitura, 1: escrita)
	syscall         	# syscall: abre arquivo e armazena em $v0 o descritor de arquivo
	
	slt  $t0, $v0, $zero	# testa se é menor que zero. se sim, houve erro.
	beq  $t0, 1, exit_error
	
	add  $t0, $v0, $zero 	# salva descritor de arquivo
	
	addi $t2, $zero, 1	# inicializa contador
	
	addi $sp, $sp, -16	# aloca espaço na pilha para salvar variáveis atuais
	sw   $ra, 12($sp)	# salva endereço de retorno
	sw   $fp,  8($sp)	# salva frame pointer atual
	sw   $t2,  4($sp)	# salva contador atual
	sw   $t0,  0($sp)	# salva descritor de arquivo
	add  $fp, $sp, $zero	# fp = sp
	
	# t0 = descritor do arquivo, t1 = endereço base do array, t2 = contador
	
	add $a0, $zero, $t2	# parâmetro esperado para função, inicialmente 1, no caso
	jal allocate_memory	# armazena em $v0 o endereço de min_size bytes recém alocados
	add $t1, $v0, $zero	# salva o endereço base do array de bytes alocado
	add $s0, $v0, $zero	
		
	lw $ra, 12($sp)		# restaura endereço de retorno - começa restauração
	lw $fp,  8($sp)		# restaura frame pointer
	lw $t2,  4($sp)		# restaura contador
	lw $t0,  0($sp)		# restaura descritor do arquivo
	add $sp, $sp, 16	# desaloca espaço na pilha - fim da restauração

read:	
	li   $v0, 14        	# carrega chamada de sistema para ler do arquivo
	add  $a0, $t0, $zero 	# guarda em $a0 o descritor do arquivo
	add  $a1, $t1, $zero   	# carrega endereço inicial de onde serão guardados os bytes lidos
	lw   $a2, min_size     	# carrega limite máximo de leitura por iteração
	syscall             	# syscall: lá no máx. $a2 bytes do arquivo e armazena em $v0 a qtde de bytes lidas de fato

	bltz $v0, exit_error

	slt  $t3, $v0, $a2	# testa se o número de bytes lido é menor que o limite por iteração 
	beq  $t3, 1, close_file # se leu menos, fecha o arquivo e salva dados lidos
				# senão, aloca mais memória para o array e continua leitura
	
	# t0 = descritor do arquivo, t1 = endereço base do array, t2 = contador	
	addi $t2, $t2, 1	# incrementa contador (fator de mult. de numero de bytes a serem alocados)
	
	addi $sp, $sp, -24	# aloca espaço na pilha para salvar estado atual
	sw   $ra, 20($sp)	# salva retorno 
	sw   $fp, 16($sp)	# salva frame pointer atual
	sw   $t0, 12($sp)	# salva descritor do arquivo
	sw   $t1, 8($sp)	# salva endereço base do array
	sw   $t2, 4($sp)	# salva contador atual
	sw   $v0, 0($sp)	# salva retorno atual
	add  $fp, $sp, $zero	# fp = sp

	# t0 = descritor do arquivo, t1 = endereço base do array, t2 = contador
	add $a0, $zero, $t2
	jal allocate_memory	# retorna em $v0 o endereço de $a0 * min_size bytes recém alocados
	add $s0, $v0, $zero	# armazena em $s0 o endereço base do array com a cópia
	
	add  $a1, $zero, $v0	# (parâmetro) endereço base do array recém alocado que armazenará a cópia - destino
	lw   $t2, 4($sp)	# carrega temporariamente contador atual
	addi $a2, $t2, -1	# $a2 = contador - 1
	lw   $t0, min_size    	# carrega temporariamente o min_size
	mul  $a2, $a2, $t0	# (parâmetro) número de elementos a serem copiados da origem = ( contador - 1 ) * min_size
	lw   $a0, 8($sp)	# (parâmetro) endereço base do array a ser copiado - origem
	add  $t3, $t2, -2
	mul  $t3, $t3, $t0
	sub  $a0, $a0, $t3

	jal copy_byte_array	# copia de origem ($a0) para ($a1) destino, ($a2) bytes
	
	lw   $ra, 20($sp)	# restaura retorno 
	lw   $fp, 16($sp)	# restaura frame pointer atual
	lw   $t0, 12($sp)	# restaura descritor do arquivo
	lw   $t1, 8($sp)	# restaura endereço base do array
	lw   $t2, 4($sp)	# restaura contador
	lw   $v0, 0($sp)	# restaura retorno atual
	addi $sp, $sp, 24	# desaloca espaço na pilha para salvar estado atual	
	
	add $t1, $s0, $zero
	
	lw   $t3, min_size
	addi $t4, $t2, -1
	mul  $t4, $t4, $t3
	add  $t1, $s0, $t4	# armazena em t1 o endereço base do array da copia, deslocado das cópias (na prox. posição vazia)
	j read	

###############################################################################################################################

close_file:
	# Antes de terinar a função, armazena em $s1 o número de bytes lidos na última iteração
	add $s1, $v0, $zero

	#Fechamento do arquivo
	li   $v0, 16        	# chamada de sistema para fechar arquivo
	add  $a0, $t0, $zero   	# descritor de arquivo a ser fechado
	syscall             	# syscall: fecha o arquivo de descritor $a0
	
	# Em $s0 já se tem o endereço base do array de bytes lido
	
	# calcula o numero de bytes lidos antes da ultima iteração
	lw  $t1, min_size	
	add $t2, $t2, -1
	mul $t0, $t1, $t2	# multiplica o contador pelo limite max por iteração
	add $s1, $s1, $t0	# s1 = bytes da última + bytes antes da última
	jr $ra

###############################################################################################################################

allocate_memory:
# Armazena em $v0 o endereço do primeiro byte dentre $a0 * min_size bytes alocados
	lw  $t0, min_size	# carrega numero inicial de bytes para alocação
	mul $t0, $t0, $a0	# multiplica numero inicial pelo fator do parâmetro 
	add $a0, $zero, $t0	# carrega como argumento da syscall o numero de bytes a ser alocado
	li  $v0, 9		# carrega chamada de sistema para alocar memória
	syscall			# syscall: aloca $a0 * min_size bytes e devolve em $v0 o endereço do primeiro deles
	jr $ra			

copy_byte_array:
# copia de origem ($a0) para destino ($a1), um determinado número de bytes ($a2)
# não retorna nada, mantendo intacto valor de $v0, $a0, $a1 e $a2
	add  $t0, $zero, $zero 	#inicializa índice do array com 0
	
copy_byte_array_loop:	
	slt  $t3, $t0, $a2	# se indice = tamanho, termina função
	beq  $t3, 0, back_stack
	add  $t1, $a0, $t0	# t1 = *origem + indice 
	lb   $t1, 0($t1)	# t1 = origem[ indice ], ou seja, t1 = byte a ser copiado
	add  $t2, $a1, $t0	# t2 = *destino + indice
	sb   $t1, 0($t2)	# destino[ indice ] = t1, ou seja, destino armazena o byte copiado
	addi $t0, $t0, 1	# indice++
	j copy_byte_array_loop 

###############################################################################################################################

convert_to_int_array:
# converte o array de bytes cujo endereço base está em $s0 em um array de inteiros
# ignora bytes que definam espaçamento ou quebra de linha (tanto em windows como em unix)
# armazena o endereço base do array de inteiros resultantes em $s2
# o array de inteiros resutante tem o mesmo tamanho que o valor que $s1 possuir
	add  $t0, $s0, $zero   		# pega o endereço base do array de bytes 
	add  $t1, $zero, $zero   	# inicia contador de leitura
	add  $t2, $zero, $zero		# inicia contador de escrita
	add  $t3, $zero, $zero		# inicia variável para inteiro lido
	addi $t8, $zero, 1		# inicia indicador de necessidade de teste pela
					# existência de sinal '-' no inteiro em construção, default 1 (necessário)
	add  $t9, $zero, $zero		# inicia variável para indicar se inteiro será positivo ou negativo
			
	add $a0, $s1, $zero		# carrega o número de bytes lidos do arquivo
	sll $a0, $a0, 2			# multiplica por 4 pois bytes serão convertidos para int, que ocupa 4 bytes
	li  $v0, 9			# carrega chamada de sistema para alocação de memória
	syscall 			# syscall: aloca $a0 bytes e retorna endereço do primeiro em $v0
	add $s2, $v0, $zero		# salva em $s2 o endereço base do array de inteiros
	
conversion_loop:
	beq  $s1, $t1, end_conversion_loop
					# se o valor do contador = número de bytes lidos do arquivo, termina loop de conversão
	add  $t4, $t1, $t0   		# soma o contador ao endereço base, pois está endereçando byte a byte
	lb   $t5, 0($t4)       		# armazena em $t5 o elemento do array

# $t0 = endereço base do array de bytes, $t1 = contador de leitura, $t2 = contador de escrita, 
# $t3 = var para o inteiro sendo construído, $t5 = último byte lido

	addi $sp, $sp, -28		# aloca espaço na pilha para salvar variáveis
	sw   $ra, 24($sp)		# salva endereço de retorno atual
	sw   $fp, 20($sp)		# salva frame pointer atual
	sw   $t0, 16($sp)		# salva endereço base do array de bytes
	sw   $t1, 12($sp) 		# salva contador de leitura
	sw   $t2,  8($sp)		# salva contador de escrita
	sw   $t3,  4($sp)		# salva var para inteiro lido
	sw   $t5,  0($sp)		# salva valor do byte lido
	add  $fp, $sp, $zero		# fp = sp
	
	add $a0, $t5, $zero		# (parâmetro) byte lido do array
	jal new_line_unix
	beq $v0, 1, restore_convert_to_int_array 
	# se é nova linha, continua restaurando estado (usa $v0 posteriormente)
	
	lw   $t1, 12($sp)		# restaura contador de leitura para obter segundo argumento
	lw   $t0, 16($sp)		# restaura endereço base do array para obter segundo argumento
	addi $t1, $t1, 1		# incrementa contador para obter próximo byte
	add  $t4, $t1, $t0   		# soma o contador ao endereço base, pois está endereçando byte a byte
	
	add  $a0, $t5, $zero		# (parâmetro) byte lido do array
	lb   $a1, ($t4)			# armazena em $a1 o elemento do array
	jal new_line_windows
	# se é nova linha, continua restaurando estado (usa $v0 posteriormente)
	
restore_convert_to_int_array:	
	lw   $ra, 24($sp)		# restaura endereço de retorno atual
	lw   $fp, 20($sp)		# restaura frame pointer atual
	lw   $t0, 16($sp)		# restaura endereço base do array de bytes
	lw   $t1, 12($sp) 		# restaura contador de leitura
	lw   $t2,  8($sp)		# restaura contador de escrita
	lw   $t3,  4($sp)		# restaura var para inteiro lido
	lw   $t5,  0($sp)		# restaura valor do byte lido
	addi $sp, $sp, 24		# desaloca espaço na pilha para salvar variáveis

	addi $t1, $t1, 1		# incrementa $t1, pois leu um byte, pelo menos (mesmo que seja LF)
	
	beq $v0, 1, conversion_loop		# se foi detectada nova linha no unix, deve ignorar 1 byte seguinte
						# pois é apenas caractere especial (Line Feed)

	addi $t1, $t1, 1			# incrementa contador, pois se detectou nova linha no windows, deve ignorar os 2 bytes seguintes
						# visto que no windows, são 2 bytes para nova linha = (CR)(LF)
	beq  $v0, 2, conversion_loop
	
	addi $t1, $t1, -2			# senão detectou em nenhum cenário, volta contador pro estado inicial antes desses testes
					
convert_byte:	
# $t0 = endereço base do array de bytes, $t1 = contador de leitura, $t2 = contador de escrita, 
# $t3 = var para o inteiro sendo construído, $t5 = último byte lido
# $s2 = endereço base do array de inteiros
	addi $t1, $t1, 1    			# incrementa contador de leitura

	li   $t7, 1				# indica que deve-se fazer um 'flush' de $t3 ao terminar o conversion_loop
	
	beqz $t8, continue_convert_byte 	# se não deve testar, continua conversão
	bne  $t5, 45, continue_convert_byte	# se não é igual a '-', continua conversão
	add  $t9, $zero, 1			# seta indicador de negatividade do inteiro para true
	add  $t5, $zero, 48			# zera $t5 para não interpretar 45 como parte do número
	add  $t8, $zero, $zero			# já testou, não deve testar até o prox. int
	
continue_convert_byte:
	beq  $t5, 32, add_int	# verifica se é espaço, se for adiciona o inteiro lido até agora
	addi $t5, $t5, -48	# senão, subtrai 48 para converter de ASCII para int
	
	mul  $t3, $t3, 10	# avança casa decimal na variável a ser escrita no array
	add  $t3, $t3, $t5	# soma o a unidade atual

	j conversion_loop	# continua o loop
    
add_int:
	sll $t6, $t2, 2		# multiplica por 4
	add $t6, $t6, $s2	# soma deslocamento (contador de escrita) ao endereço base do array de inteiro
	
	seq  $t4, $t9, 1	# testa se o inteiro deve ser negativo
	beqz $t4, do_add_int	# se não é, pula logo para a inserção no vetor
	mul  $t3, $t3, -1
	
do_add_int:
	sw  $t3, 0($t6)		# armazena inteiro construído da posição calculada
	li  $t7, 0		# indica que não deve-se fazer um 'flush' de $t5 ao terminar o conversion_loop, visto que já escreveu $t3
	
	add  $t3, $zero, $zero	# zera valor da var para inteiro sendo construído
	addi $t8, $zero, 1      # indica que deve-se testar por presença de sinal
	add  $t9, $zero, $zero	# zera indicador de presença de sinal
	addi $t2, $t2, 1 	# incrementa contador de escrita 
	j conversion_loop		

end_conversion_loop:
	beq $t7, 1, add_int
	add $s4, $t2, $zero	# armazena em $s4 o número de inteiros escritos
	jr $ra  

###############################################################################################################################

new_line_windows:
# retorna 2 se conteúdo em $a0 e $a1 são bytes que indicam nova linha no windows.
# retorna 0 caso contrário
	add  $t0, $a0, -13 
	beq  $t0, $zero, new_line_windows_lf
	
not_new_line_windows_lf:
	add  $v0, $zero, $zero
	jr   $ra
	
new_line_windows_lf:
	add  $t0, $a1, -10
	bne  $t0, $zero, not_new_line_windows_lf
	addi $v0, $zero, 2
	jr   $ra

new_line_unix:
# retorna 1 se conteúdo em $a0 é um byte que indica nova linha em sistemas unix.
# retorna 0 caso contrário
	add $t0, $a0, -10
	bne $t0, $zero, not_new_line_unix_lf
	add $v0, $zero, 1
	jr $ra
	
not_new_line_unix_lf:
	add  $v0, $zero, $zero
	jr   $ra
	
###############################################################################################################################
						
type_of_sort: 
	li $v0, 51 #chamada do sistema para abrir dialog de input de int
	la $a0, input_sort_msg #colocando mensagem a ser exibida no dialog
	syscall
	
	bne $a1, $zero, exit_error #se o resultado de $a1 não for zero é porque deu erro
	
	add $v0, $a0, $zero #colocando no registrador de retorno o resultado do tipo de ordenação escolhido
	
	jr $ra

###############################################################################################################################
		
ordena:	
	addi $sp, $sp, -4 
	sw   $ra, 0($sp) #salvando na pilha o $ra, para saber para onde voltar

	addi $t1, $zero, 1 
	beq $a3, $t1, choose_quick_sort #se a escolha for 1, vai para o quick sort
	
	addi $t1, $zero, 2
	beq $a3, $t1, choose_insertion_sort #se a escolha for 2, vai para insertion sort
	
	j exit_error # se não escolheu certo, sai do programa
	
###############################################################################################################################

choose_quick_sort:
	jal quicksort
	j return_from_sort

choose_insertion_sort:	
	jal insertion_sort
	
return_from_sort:	
	lw $ra,  0($sp)
	add $sp, $sp, 4
	
	jr $ra
	
###############################################################################################################################

quicksort:
# $a0 - endereço do primeiro byte do array de int
# $a1 - tamanho do array
	addi $a2, $a1, -1
	add  $a1, $zero, $zero
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	jal  quicksort_recursion
	lw   $ra, 0($sp)
	addi $sp, $sp, 4

	jr   $ra

quicksort_recursion:
# $a0 - endereço do primeiro byte do array de int
# $a1 - posição inicial
# $a2 - posição final
	slt  $t0, $a1, $a2	# se  pos inicial < pos final, deve ordenar
	beqz $t0, back_stack
	
	addi $sp, $sp, -16
	sw   $ra, 12($sp)
	sw   $a2 , 8($sp)
	sw   $a1,  4($sp)
	sw   $a0,  0($sp)
	jal particao 
	lw   $ra, 12($sp)
	lw   $a2,  8($sp)
	lw   $a1,  4($sp)
	lw   $a0,  0($sp)
	add  $sp, $sp, 16
	
	add  $t0, $v0, $zero	# armazena índice da particao  		
	
	add  $t1, $a2, $zero	# salva para uso posterior

	addi $sp, $sp, -16
	sw   $ra, 12($sp)
	sw   $t0,  8($sp)
	sw   $t1,  4($sp)
	sw   $a1,  0($sp) 

	add  $a2, $t0, -1	# chama recursao para pos inicial atual, indice da particao - 1
	jal quicksort_recursion

	lw   $ra, 12($sp)
	lw   $t0,  8($sp)
	lw   $t1,  4($sp)
	lw   $a1,  0($sp) 
	addi $sp, $sp, 16
	
	add  $a2, $t1, $zero	# restaura a2 - pos final atual
	add  $a1, $t0, 1	# chama recursao para indice da particao + 1, pos final atual
	
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	jal quicksort_recursion
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	j back_stack

particao:
# particiona o array dado em menor ou igual um pivot ou maior que o mesmo
# $a0 - Endereço base, $a1 - indíce do primeiro elemento, $a2 - índice do último elemento
# retorna posicao do divisor (índice do pivot que divide o array em particoes)

# $t0 - pivot, $t1 - limite de menores ou iguais ou pivot
# $t2 - indice para percorrer sub-array
	sll  $t0, $a2, 2	# multiplica por 4
	add  $t0, $t0, $a0	# calcula endereco do pivot
	lw   $t0, 0($t0)	# armazena pivot 
	
	addi $t1, $a1, -1	# inicializa variável do limite de menores ou iguais
	add  $t2, $a1, $zero	# inicializa indice com primeira posicao do sub array
	
particao_loop:
	slt  $t3, $t2, $a2	# enquanto indice < último ind.
	beq  $t3, $zero, end_particao
	
	sll  $t3, $t2,  2	# multiplica indice por 4
	add  $t3, $t3, $a0	# calcula endereco da posicao no array
	lw   $t4, 0($t3)	# carrega elemento do array
	
	sle  $t5, $t4, $t0	# testa se é menor ou igual ao pivot
	beq  $t5, $zero, continue_particao_loop # se é maior, continua loop
	addi $t1, $t1, 1	# senão, incrementa limite de menores ou iguais, pois achou um novo menor ou igual

# faz swap
	sll  $t5, $t1, 2
	add  $t5, $t5, $a0	# calcula endereço em memoria do limite de menores ou iguais
	lw   $t6, 0($t5)	# armazena elemento da posicao
	sw   $t4, 0($t5)	# substitui um valor
	sw   $t6, 0($t3)	# substitui outro valor  
# fim do swap	

continue_particao_loop:
	add  $t2, $t2, 1	# incrementa indice do sub array
	j particao_loop

end_particao:
# reposicionamento do pivot - outro swap
	addi $t1, $t1, 1	# calcula offset da nova posicao
	sll  $t2, $t1, 2	# multiplica por 4
	add  $t2, $t2, $a0	# calcula o endereco da nova posicao
	lw   $t3, 0($t2)	# obtem antigo valor da nova posicao
	sw   $t0, 0($t2)	# armazena pivot na nova posicao
	sll  $t0, $a2, 2
	add  $t0, $t0, $a0	# calcula antigo endereco do pivot
	sw   $t3, 0($t0)	# armazena elemento na pos antiga do pivot
	
	add  $v0, $t1, $zero	# armazena para retorno

	jr $ra

###############################################################################################################################

insertion_sort:
	#$a0 = base do array de inteiros    $a1 = numero de elementos no array de inteiros
	add $t0, $a0, $zero
	
	add $a0, $t0, $zero
	
	addi $t0, $zero, 1 
	add $t1, $zero, $zero
	add $t2, $zero, $zero
	add $t3, $zero, $a1
	# $t0 = i   $t1 = j   $t2 = v   $t3 = fim
	
loop_insertion:
	slt $t4, $t0, $t3 # verifica se i < fim
	beq $t4, $zero, back_stack # senão sai do loop
	
	sll $t4, $t0, 2 # faz i * 4  para calcular posição do array
	add $t4, $t4, $a0 #calcula posição do array
	lw $t2, 0($t4) # salva em v o valor de A[i]
	add $t1, $zero, $t0 # deixa j igual a i
	
	addi $sp, $sp, -4 # aloca posição na pilha
	sw   $ra, 0($sp) # salva a posição de $ra na pilha
	
	jal loop_to_move_insertion
	
	lw   $ra,  0($sp) #pega o valor de $ra
	addi $sp, $sp, 4 # volta o valor da pilha para o original
	
	sll $t4, $t1, 2 # faz j * 4 para calcular a posição do array
	add $t4, $t4, $a0 #pega posição do A[j]
	sw $t2, 0($t4) # A[j] = v
	
	addi $t0, $t0, 1 # i++
	j loop_insertion
	
loop_to_move_insertion:
	slt $t4, $zero, $t1 # j > 0
	beq $t4, $zero, back_stack # if j <= 0, termina loop
	
	addi $t4, $t1, -1 # $t4 = j - 1
	sll $t4, $t4, 2 # faz (j-1) * 4 para calcular a posição do array
	add $t5, $t4, $a0 #calcula posição do array
	lw $t5, 0($t5) # pega A[j-1]
	slt $t4, $t2, $t5 # verifica se v < A[j-1]
	beq $t4, $zero, back_stack # se não for, termina o loop
	
	sll $t4, $t1, 2  # faz j * 4 para calcular a posição do array
	add $t4, $t4, $a0 #calcula posição de A[j]
	sw $t5, 0($t4) #salva A[j-1] em A[j]
	addi $t1, $t1, -1 # j--
	
	j loop_to_move_insertion
	
###############################################################################################################################

convert_to_byte_array:
	add $a0, $s1, 1		# carrega argumento para funcao de alocacao de memoria, o numero de bytes a serem alocados
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	jal allocate_memory	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	
	add $t0, $zero, $zero 	# inicializa contador, para deslocamento no array de inteiro
	add $t1, $zero, $zero	# inicializa contador, para deslocamento no array de bytes
	add $t2, $v0, $zero	# inicializa variável para armazenar a string a ser escrita
	add $s0, $v0, $zero
	
convert_to_byte_array_loop:
	beq $t0, $s4, end_convert_to_byte_array	# se é do tamanho do array de inteiros, termina
	sll $t3, $t0, 2		# multiplica por 4, endereçamento por word
	add $t3, $t3, $s2	# calcula o endereço do elemento atual do array
		
	lw  $t3, 0($t3)		# carrega o elemento, o inteiro no caso
	
	slt $t4, $t3, $zero	# testa se eh negativo
	bne $t4, 1, convert_int	# se nao eh, continua

	mul  $t3, $t3, -1	# se eh torna positivo
	add  $t5, $zero, 45	# adiciona hifen para negativo
	add  $t6, $s0, $t1	# carrega endereco + deslocamento em array de bytes
	sb   $t5, 0($t6)	# escreve hifen em array de bytes
	addi $t1, $t1, 1	# incrementa deslocamento para prox. posicao
	
convert_int:
	li $t4, 1 #inicializa potencia como 1
	li $t5, 10 #faremos tudo com base nas potencias de 10	
	
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	jal calc_pot
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	
	j get_numbers
	
get_numbers:
	blez $t4, write_space # se potencia <= 0 acaba o loop
	slt $t6, $t3, $t4 #verifica se o numero é menor que a potencia
	beq $t6, $zero, write_quotient #se não for menor, imprime o quociente
	beq $t6, 1, write_zero # se for menor, imprime um zero


write_zero:
    add  $t7, $s0, $t1	# calcula endereco do prox. byte a ser escrito	
	addi $t6, $zero, 48	# adiciona base do ASCII para digito zero
	sb   $t6, 0($t7)	# poe no array
	add  $t1, $t1, 1	# incrementa deslocamento do array de byte
	
	div $t4, $t5 #divide potencia por 10
	mflo $t4
	
	j get_numbers
	
write_quotient:
	div $t3, $t4 #divide o número pela potencia e coloca em lo o quociente e em hi o resto
	mflo $t6 #quociente
    mfhi $t3 # atualiza o número para o resto entre o numero antigo e a potencia
    
    add  $t7, $s0, $t1	# calcula endereco do prox. byte a ser escrito	
	addi $t6, $t6, 48	# adiciona base do ASCII
	sb   $t6, 0($t7)	# poe no array
	add  $t1, $t1, 1	# incrementa deslocamento do array de byte
	
	div $t4, $t5 #divide potencia por 10
	mflo $t4
	
	j get_numbers
	
calc_pot:
	div $t3, $t4 #divide o número pela potencia e coloca em lo o quociente
	mflo $t6
	slt $t6, $t6, $t5 #verifica se o número / potencia é menor que 10
	beq $t6, 1, back_stack
	
	mul $t4, $t4, $t5 # faz potencia *= 10
	
	j calc_pot

write_space:
	add  $t6, $s0, $t1	# calcula endereco do prox. byte a ser escrito
	addi $t7, $zero, 32	# ultimo digito a ser escrito
	sb   $t7, 0($t6)	# escreve ultimo digito
	
	addi $t1, $t1, 1	# incrementa deslocamento no array de byte
	addi $t0, $t0, 1	# incrementa deslocamento no array de inteiro
	
	j convert_to_byte_array_loop

end_convert_to_byte_array:
	add  $t6, $t6, 1	# calcula endereco do prox. byte a ser escrito
	add  $t7, $zero, $zero  # terminator
	sb   $t7, 0($t6)	# escreve espaco em branco, o divisor de numeros
	jr   $ra

###############################################################################################################################

write_file:
	la   $a0, file_name	# Carrrega nome do arquivo
	addi $a1, $zero, 9	# Abre o arquivo para no modo de append
	li   $v0, 13		# chamada de sistema para abrir o arquivo
	syscall
	
	blt $v0, $zero, exit_error
	
	add $t0, $v0, $zero	# salva o descritor de arquivo	
	
	addi $a0, $zero, 4	# inicializa argumento, numero de bytes a serem alocados
	li   $v0, 9		# chamada para alocar $a0 bytes no heap de memoria
	syscall
	
	addi $t1, $zero, 13 	# Começa quebra de linha x2
	sb   $t1, 0($v0)	# Carriage return
	sb   $t1, 2($v0)	# Carriage return
	addi $t1, $zero, 10	
	sb   $t1, 1($v0)	# Line feed
	sb   $t1, 3($v0)	# Line feed
	# Termina de quebrar a linha x2
	
	add  $a0, $t0, $zero	# armazena descritor de arquivo onde escrevera
	add  $a1, $v0, $zero	# armazena endereco recem alocado onde foram inseridas as quebras de linha
	addi $a2, $zero, 4	# armazena quantidade de bytes para escrever (mesma que alocou para as quebras)
	li   $v0, 15		# chamada para escrita
	syscall	
	
	blt $v0, $zero, exit_error
	
	add $a1, $s0, $zero	# armazena endereco base do array de bytes, ordenado
	add $a2, $s1, $zero	# armazena tamanho do array de bytes
	li  $v0, 15		# chamada para escrita
	syscall	
	
	blt $v0, $zero, exit_error

	li  $v0, 16		# fecha o arquivo
	syscall
	
	jr $ra

###############################################################################################################################

back_stack:
	jr $ra

###############################################################################################################################

exit_error:
# Exibe msg de erro e termina o programa
	la $a0, exit_error_msg
	li $v0, 4
	syscall
	j exit	

exit:
# Termina o programa
    li $v0,10       #fim
	syscall
	
###############################################################################################################################

.data
exit_error_msg:
	.asciiz "Um erro ocorreu. Terminando o programa."
input_file_name_msg:
	.asciiz "Digite o nome do seu arquivo: "
input_sort_msg:	
	.asciiz "Digite 1 para quick sort e 2 para insertion sort"
file_name: 		# nome do arquivo que será colocado pelo usuário
	.asciiz ""	
array:
	.align 2
	.space 1024
min_size:
	.word 256		# número inicial de bytes a serem lidos do arquivo
