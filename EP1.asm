.data
new_line:           	# nova linha, para prints - facilita debug
    	.asciiz "\n"
new_space:           	# novo espa�o, para prints - facilita debug
    	.asciiz " "
byte_array_ended:	# msg para print ao terminar de printar um array de bytes - facilita debug
	.asciiz "Fim do array de bytes\n"
bytes_readed:		# msg para print - facilita debug
	.asciiz "N�mero de bytes lidos: "
int_array_ended:	# msg para print - facilita debug
	.asciiz "Fim do array de inteiros\n"
int_readed:
	.asciiz "N�mero de inteiros: "
exit_error_msg:
	.asciiz "Um erro ocorreu. Terminando o programa."
input_file_name_msg:
	.asciiz "Digite o nome do seu arquivo: "
input_sort_msg:	
	.asciiz "Digite 1 para quick sort e 2 para insertion sort"
quicksort_msg:
	.asciiz "\nQuick Sort"
insertion_sort_msg:
	.asciiz "\nInsertion Sort"
file_name: 		# nome do arquivo que ser� colocado pelo usu�rio
	.asciiz ""	
array:
	.align 2
	.space 1024
min_size:
	.word 256		# n�mero inicial de bytes a serem lidos do arquivo
.text
.globl main
main:
	jal get_file_name
	add $a0, $v0, $zero
	
	jal read_file
	jal print_byte_array
	jal convert_to_int_array
	jal print_int_array
	
	jal choose_sort
	
	jal print_int_array
	jal convert_to_byte_array
	jal print_byte_array
	
	jal write_file
	
	j exit
	
choose_sort:
	li $v0, 51 #chamada do sistema para abrir dialog de input de int
	la $a0, input_sort_msg #colocando mensagem a ser exibida no dialog
	syscall
	
	bne $a1, $zero, exit_error #se o resultado de $a1 não for zero é porque deu erro
	la $t0, 0($a0) #pega o sort escolhido pelo usuário
	
	add $a0, $s2, $zero # base do array de inteirquos
	add $a1, $s4, $zero # numero de elementos no array de inteiros
	
	addi $sp, $sp, -4 
	sw   $ra, 0($sp) #salvando na pilha o $ra, para saber para onde voltar

	addi $t1, $zero, 1 
	beq $t0, $t1, choose_quick_sort #se a escolha for 1, vai para o quick sort
	
	addi $t1, $zero, 2
	beq $t0, $t1, choose_insertion_sort #se a escolha for 2, vai para insertion sort
	
	j exit_error # se não escolheu certo, sai do programa
	
choose_quick_sort:
	jal quicksort
	
	lw $ra,  0($sp)
	add $sp, $sp, 4
	
	jr $ra

choose_insertion_sort:	
	jal insertion_sort
	
	lw $ra,  0($sp)
	add $sp, $sp, 4
	
	jr $ra

exit:
# Termina o programa
    li $v0,10       #fim
	syscall

exit_error:
# Exibe msg de erro e termina o programa
	la $a0, exit_error_msg
	li $v0, 4
	syscall
	j exit	
get_file_name:
# Retorna em $v0 o endere�o para o nome do arquivo. Usa do dialog para input
	li $v0, 54 		# carrega chamada de sistema para mostrar um dialog para input de string
	la $a0, input_file_name_msg # carrega a mensagem a ser mostrada no dialog
	la $a1, file_name 	# carrega o local onde ser� armazenado o input do usu�rio
	lw $a2, min_size 	# carrega o n�mero de bytes que ser�o lidos
	syscall 		# coloca em $a1 o valor do status:
				# (0: OK status. -2: Cancel. -3: input.vazio. -4: tamanho do input maior)
	
	bne $a1, $zero, exit_error 	# se o status foi diferente de 0, sai do programa
	
	la  $v0, file_name		# carrega o nome do arquivo em $v0, para retorno

# inicializando contador do loop para limpar o nome do arquivo e 
# tirar o caractere que determina o final da string que n�o serve quando for usar para abrir o arquivo	
    	li  $t0, 0       	
    	lw  $t1, min_size	      	# inicializando o final do loop
    
remove_line_feed_loop:
	beq $t0, $t1, end_remove_line_feed_loop	# verifica se o loop chegou ao final
        lb  $t3, file_name($t0) 		# pega o byte de determinada posi��o do nome do arquivo
        bne $t3, 10, cont_remove_line_feed_loop # verifica se esse byte cont�m o caracter 10 (linefeed)
        sb  $zero, file_name($t0) 	 	# se for igual ao caracter 10, substitui ele por zero
	j   end_remove_line_feed_loop
cont_remove_line_feed_loop:
    	addi $t0, $t0, 1 			# incrementa o contador
	j remove_line_feed_loop
end_remove_line_feed_loop:
	jr $ra

allocate_memory:
# Armazena em $v0 o endere�o do primeiro byte dentre $a0 * min_size bytes alocados
	lw  $t0, min_size	# carrega numero inicial de bytes para aloca��o
	mul $t0, $t0, $a0	# multiplica numero inicial pelo fator do par�metro 
	add $a0, $zero, $t0	# carrega como argumento da syscall o numero de bytes a ser alocado
	li  $v0, 9		# carrega chamada de sistema para alocar mem�ria
	syscall			# syscall: aloca $a0 * min_size bytes e devolve em $v0 o endere�o do primeiro deles
	jr $ra			

copy_byte_array:
# copia de origem ($a0) para destino ($a1), um determinado n�mero de bytes ($a2)
# n�o retorna nada, mantendo intacto valor de $v0, $a0, $a1 e $a2
	add  $t0, $zero, $zero 	#inicializa �ndice do array com 0
copy_byte_array_loop:	
	slt  $t3, $t0, $a2	# se indice = tamanho, termina fun��o
	beq  $t3, 0, end_copy_byte_array
	add  $t1, $a0, $t0	# t1 = *origem + indice 
	lb   $t1, 0($t1)	# t1 = origem[ indice ], ou seja, t1 = byte a ser copiado
	add  $t2, $a1, $t0	# t2 = *destino + indice
	sb   $t1, 0($t2)	# destino[ indice ] = t1, ou seja, destino armazena o byte copiado
	addi $t0, $t0, 1	# indice++
	j copy_byte_array_loop 
end_copy_byte_array:
	jr $ra

read_file:
# Abre pra leitura o arquivo de entrada especificado em $a0
	
	li   $v0, 13        	# carrega chamada de sistema para abertura de arquivo
	# � esperado que $a0 contenha o endere�o para o nome do arquivo
	li   $a1, 0     	# par�metro para abrir para leitura (0: leitura, 1: escrita)
	syscall         	# syscall: abre arquivo e armazena em $v0 o descritor de arquivo
	
	slt  $t0, $v0, $zero	# testa se � menor que zero. se sim, houve erro.
	beq  $t0, 1, exit_error
	
	add  $t0, $v0, $zero 	# salva descritor de arquivo
	
	addi $t2, $zero, 1	# inicializa contador
	
	addi $sp, $sp, -16	# aloca espa�o na pilha para salvar vari�veis atuais
	sw   $ra, 12($sp)	# salva endere�o de retorno
	sw   $fp,  8($sp)	# salva frame pointer atual
	sw   $t2,  4($sp)	# salva contador atual
	sw   $t0,  0($sp)	# salva descritor de arquivo
	add  $fp, $sp, $zero	# fp = sp
	
	# t0 = descritor do arquivo, t1 = endere�o base do array, t2 = contador
	
	add $a0, $zero, $t2	# par�metro esperado para fun��o, inicialmente 1, no caso
	jal allocate_memory	# armazena em $v0 o endere�o de min_size bytes rec�m alocados
	add $t1, $v0, $zero	# salva o endere�o base do array de bytes alocado
	add $s0, $v0, $zero	
		
	lw $ra, 12($sp)		# restaura endere�o de retorno - come�a restaura��o
	lw $fp,  8($sp)		# restaura frame pointer
	lw $t2,  4($sp)		# restaura contador
	lw $t0,  0($sp)		# restaura descritor do arquivo
	add $sp, $sp, 16	# desaloca espa�o na pilha - fim da restaura��o

read:	
	li   $v0, 14        	# carrega chamada de sistema para ler do arquivo
	add  $a0, $t0, $zero 	# guarda em $a0 o descritor do arquivo
	add  $a1, $t1, $zero   	# carrega endere�o inicial de onde ser�o guardados os bytes lidos
	lw   $a2, min_size     	# carrega limite m�ximo de leitura por itera��o
	syscall             	# syscall: l� no m�x. $a2 bytes do arquivo e armazena em $v0 a qtde de bytes lidas de fato

	bltz $v0, exit_error

	slt  $t3, $v0, $a2	# testa se o n�mero de bytes lido � menor que o limite por itera��o 
	beq  $t3, 1, close_file # se leu menos, fecha o arquivo e salva dados lidos
				# sen�o, aloca mais mem�ria para o array e continua leitura
	
	# t0 = descritor do arquivo, t1 = endere�o base do array, t2 = contador	
	addi $t2, $t2, 1	# incrementa contador (fator de mult. de numero de bytes a serem alocados)
	
	addi $sp, $sp, -24	# aloca espa�o na pilha para salvar estado atual
	sw   $ra, 20($sp)	# salva retorno 
	sw   $fp, 16($sp)	# salva frame pointer atual
	sw   $t0, 12($sp)	# salva descritor do arquivo
	sw   $t1, 8($sp)	# salva endere�o base do array
	sw   $t2, 4($sp)	# salva contador atual
	sw   $v0, 0($sp)	# salva retorno atual
	add  $fp, $sp, $zero	# fp = sp

	# t0 = descritor do arquivo, t1 = endere�o base do array, t2 = contador
	add $a0, $zero, $t2
	jal allocate_memory	# retorna em $v0 o endere�o de $a0 * min_size bytes rec�m alocados
	add $s0, $v0, $zero	# armazena em $s0 o endere�o base do array com a c�pia
	
	add  $a1, $zero, $v0	# (par�metro) endere�o base do array rec�m alocado que armazenar� a c�pia - destino
	lw   $t2, 4($sp)	# carrega temporariamente contador atual
	addi $a2, $t2, -1	# $a2 = contador - 1
	lw   $t0, min_size    	# carrega temporariamente o min_size
	mul  $a2, $a2, $t0	# (par�metro) n�mero de elementos a serem copiados da origem = ( contador - 1 ) * min_size
	lw   $a0, 8($sp)	# (par�metro) endere�o base do array a ser copiado - origem
	add  $t3, $t2, -2
	mul  $t3, $t3, $t0
	sub  $a0, $a0, $t3

	jal copy_byte_array	# copia de origem ($a0) para ($a1) destino, ($a2) bytes
	
	lw   $ra, 20($sp)	# restaura retorno 
	lw   $fp, 16($sp)	# restaura frame pointer atual
	lw   $t0, 12($sp)	# restaura descritor do arquivo
	lw   $t1, 8($sp)	# restaura endere�o base do array
	lw   $t2, 4($sp)	# restaura contador
	lw   $v0, 0($sp)	# restaura retorno atual
	addi $sp, $sp, 24	# desaloca espa�o na pilha para salvar estado atual	
	
	add $t1, $s0, $zero
	
	lw   $t3, min_size
	addi $t4, $t2, -1
	mul  $t4, $t4, $t3
	add  $t1, $s0, $t4	# armazena em t1 o endere�o base do array da copia, deslocado das c�pias (na prox. posi��o vazia)
	j read	
	
close_file:
	# Antes de terinar a fun��o, armazena em $s1 o n�mero de bytes lidos na �ltima itera��o
	add $s1, $v0, $zero

	#Fechamento do arquivo
	li   $v0, 16        	# chamada de sistema para fechar arquivo
	add  $a0, $t0, $zero   	# descritor de arquivo a ser fechado
	syscall             	# syscall: fecha o arquivo de descritor $a0
	
	# Em $s0 j� se tem o endere�o base do array de bytes lido
	
	# calcula o numero de bytes lidos antes da ultima itera��o
	lw  $t1, min_size	
	add $t2, $t2, -1
	mul $t0, $t1, $t2	# multiplica o contador pelo limite max por itera��o
	add $s1, $s1, $t0	# s1 = bytes da �ltima + bytes antes da �ltima
    	jr $ra
    
print_byte_array: 
    	add $a0, $s0, $zero	# carrega endere�o da posi��o inicial do array de bytes que cont�m o arquivo
    	li $v0, 4		# carrega comando para print, considerando o endere�o em $a0 como uma string
    	syscall			# chamada de sistema para printar
    	la $a0, new_line    	# printa nova linha para facilitar debug
    	syscall
    	la $a0, byte_array_ended 
    	syscall

	la $a0, bytes_readed
	li $v0, 4
	syscall
	add $a0, $s1, $zero
	li $v0, 1
	syscall
	la $a0, new_line
	li $v0, 4
	syscall    
    	jr $ra
    
convert_to_int_array:
# converte o array de bytes cujo endere�o base est� em $s0 em um array de inteiros
# ignora bytes que definam espa�amento ou quebra de linha (tanto em windows como em unix)
# armazena o endere�o base do array de inteiros resultantes em $s2
# o array de inteiros resutante tem o mesmo tamanho que o valor que $s1 possuir
	add  $t0, $s0, $zero   		# pega o endere�o base do array de bytes 
	add  $t1, $zero, $zero   	# inicia contador de leitura
	add  $t2, $zero, $zero		# inicia contador de escrita
	add  $t3, $zero, $zero		# inicia vari�vel para inteiro lido
	addi $t8, $zero, 1		# inicia indicador de necessidade de teste pela
					# exist�ncia de sinal '-' no inteiro em constru��o, default 1 (necess�rio)
	add  $t9, $zero, $zero		# inicia vari�vel para indicar se inteiro ser� positivo ou negativo
			
	add $a0, $s1, $zero		# carrega o n�mero de bytes lidos do arquivo
	sll $a0, $a0, 2			# multiplica por 4 pois bytes ser�o convertidos para int, que ocupa 4 bytes
	li  $v0, 9			# carrega chamada de sistema para aloca��o de mem�ria
	syscall 			# syscall: aloca $a0 bytes e retorna endere�o do primeiro em $v0
	add $s2, $v0, $zero		# salva em $s2 o endere�o base do array de inteiros
	
conversion_loop:
	beq  $s1, $t1, end_conversion_loop
					# se o valor do contador = n�mero de bytes lidos do arquivo, termina loop de convers�o
	add  $t4, $t1, $t0   		# soma o contador ao endere�o base, pois est� endere�ando byte a byte
	lb   $t5, 0($t4)       		# armazena em $t5 o elemento do array

# $t0 = endere�o base do array de bytes, $t1 = contador de leitura, $t2 = contador de escrita, 
# $t3 = var para o inteiro sendo constru�do, $t5 = �ltimo byte lido

	addi $sp, $sp, -28		# aloca espa�o na pilha para salvar vari�veis
	sw   $ra, 24($sp)		# salva endere�o de retorno atual
	sw   $fp, 20($sp)		# salva frame pointer atual
	sw   $t0, 16($sp)		# salva endere�o base do array de bytes
	sw   $t1, 12($sp) 		# salva contador de leitura
	sw   $t2,  8($sp)		# salva contador de escrita
	sw   $t3,  4($sp)		# salva var para inteiro lido
	sw   $t5,  0($sp)		# salva valor do byte lido
	add  $fp, $sp, $zero		# fp = sp
	
	add $a0, $t5, $zero		# (par�metro) byte lido do array
	jal new_line_unix
	beq $v0, 1, restore_convert_to_int_array 
	# se � nova linha, continua restaurando estado (usa $v0 posteriormente)
	
	lw   $t1, 12($sp)		# restaura contador de leitura para obter segundo argumento
	lw   $t0, 16($sp)		# restaura endere�o base do array para obter segundo argumento
	addi $t1, $t1, 1		# incrementa contador para obter pr�ximo byte
	add  $t4, $t1, $t0   		# soma o contador ao endere�o base, pois est� endere�ando byte a byte
	
	add  $a0, $t5, $zero		# (par�metro) byte lido do array
	lb   $a1, ($t4)			# armazena em $a1 o elemento do array
	jal new_line_windows
	# se � nova linha, continua restaurando estado (usa $v0 posteriormente)
	
restore_convert_to_int_array:	
	lw   $ra, 24($sp)		# restaura endere�o de retorno atual
	lw   $fp, 20($sp)		# restaura frame pointer atual
	lw   $t0, 16($sp)		# restaura endere�o base do array de bytes
	lw   $t1, 12($sp) 		# restaura contador de leitura
	lw   $t2,  8($sp)		# restaura contador de escrita
	lw   $t3,  4($sp)		# restaura var para inteiro lido
	lw   $t5,  0($sp)		# restaura valor do byte lido
	addi $sp, $sp, 24		# desaloca espa�o na pilha para salvar vari�veis

	addi $t1, $t1, 1		# incrementa $t1, pois leu um byte, pelo menos (mesmo que seja LF)
	
	beq $v0, 1, conversion_loop		# se foi detectada nova linha no unix, deve ignorar 1 byte seguinte
						# pois � apenas caractere especial (Line Feed)

	addi $t1, $t1, 1			# incrementa contador, pois se detectou nova linha no windows, deve ignorar os 2 bytes seguintes
						# visto que no windows, s�o 2 bytes para nova linha = (CR)(LF)
	beq  $v0, 2, conversion_loop
	
	addi $t1, $t1, -2			# sen�o detectou em nenhum cen�rio, volta contador pro estado inicial antes desses testes
					
convert_byte:	
# $t0 = endere�o base do array de bytes, $t1 = contador de leitura, $t2 = contador de escrita, 
# $t3 = var para o inteiro sendo constru�do, $t5 = �ltimo byte lido
# $s2 = endere�o base do array de inteiros
	addi $t1, $t1, 1    			# incrementa contador de leitura

	li   $t7, 1				# indica que deve-se fazer um 'flush' de $t3 ao terminar o conversion_loop
	
	beqz $t8, continue_convert_byte 	# se n�o deve testar, continua convers�o
	bne  $t5, 45, continue_convert_byte	# se n�o � igual a '-', continua convers�o
	add  $t9, $zero, 1			# seta indicador de negatividade do inteiro para true
	add  $t5, $zero, 48			# zera $t5 para n�o interpretar 45 como parte do n�mero
	add  $t8, $zero, $zero			# j� testou, n�o deve testar at� o prox. int
	
continue_convert_byte:
	beq  $t5, 32, add_int	# verifica se � espa�o, se for adiciona o inteiro lido at� agora
	addi $t5, $t5, -48	# sen�o, subtrai 48 para converter de ASCII para int
	
	mul  $t3, $t3, 10	# avan�a casa decimal na vari�vel a ser escrita no array
	add  $t3, $t3, $t5	# soma o a unidade atual

	j conversion_loop	# continua o loop
    
add_int:
	sll $t6, $t2, 2		# multiplica por 4
	add $t6, $t6, $s2	# soma deslocamento (contador de escrita) ao endere�o base do array de inteiro
	
	seq  $t4, $t9, 1	# testa se o inteiro deve ser negativo
	beqz $t4, do_add_int	# se n�o �, pula logo para a inser��o no vetor
	mul  $t3, $t3, -1
do_add_int:
	sw  $t3, 0($t6)		# armazena inteiro constru�do da posi��o calculada
	li  $t7, 0		# indica que n�o deve-se fazer um 'flush' de $t5 ao terminar o conversion_loop, visto que j� escreveu $t3
	
	add  $t3, $zero, $zero	# zera valor da var para inteiro sendo constru�do
	addi $t8, $zero, 1      # indica que deve-se testar por presen�a de sinal
	add  $t9, $zero, $zero	# zera indicador de presen�a de sinal
	addi $t2, $t2, 1 	# incrementa contador de escrita 
	j conversion_loop		

end_conversion_loop:
	beq $t7, 1, add_int
	add $s4, $t2, $zero	# armazena em $s4 o n�mero de inteiros escritos
	jr $ra  

print_int_array:
# $s2 = endere�o base do array de inteiros, $s4 = n�mero de inteiros escritos no array
	la $a0, new_line
	li $v0, 4
	syscall

	add $t0, $zero, $zero	# inicia contador
loop_print_int_array:
	beq $t0, $s4, end_print_int_array
	sll $t1, $t0, 2
	add $t1, $t1, $s2
	lw  $a0, 0($t1)
	li  $v0, 1
	syscall
	la  $a0, new_space	# imprime espa�o
	li  $v0, 4
	syscall
	addi $t0, $t0, 1	# decrementa contador
	j loop_print_int_array
end_print_int_array:
	la $a0, new_line
	li $v0, 4
	syscall	
	la $a0, int_array_ended
	syscall	
	la $a0, int_readed
	syscall
	add $a0, $s4, $zero
	li $v0, 1
	syscall
	la $a0, new_line
	li $v0, 4
	syscall  
	jr $ra
new_line_windows:
# retorna 2 se conte�do em $a0 e $a1 s�o bytes que indicam nova linha no windows.
# retorna 0 caso contr�rio
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
# retorna 1 se conte�do em $a0 � um byte que indica nova linha em sistemas unix.
# retorna 0 caso contr�rio
	add $t0, $a0, -10
	bne $t0, $zero, not_new_line_unix_lf
	add $v0, $zero, 1
	jr $ra
not_new_line_unix_lf:
	add  $v0, $zero, $zero
	jr   $ra
	
#########################################################################	
#########################################################################
#########################################################################
quicksort:
# $a0 - endere�o do primeiro byte do array de int
# $a1 - tamanho do array
	addi $a2, $a1, -1
	add  $a1, $zero, $zero
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	jal  quicksort_recursion
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	
	li $v0, 4
	la $a0, quicksort_msg
	syscall
	
	jr   $ra

quicksort_recursion:
# $a0 - endere�o do primeiro byte do array de int
# $a1 - posi��o inicial
# $a2 - posi��o final
	slt  $t0, $a1, $a2	# se  pos inicial < pos final, deve ordenar
	beqz $t0, end_quicksort_recursion
	
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
	
	add  $t0, $v0, $zero	# armazena �ndice da particao  		
	
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
end_quicksort_recursion:
	jr   $ra

particao:
# particiona o array dado em menor ou igual um pivot ou maior que o mesmo
# $a0 - Endere�o base, $a1 - ind�ce do primeiro elemento, $a2 - �ndice do �ltimo elemento
# retorna posicao do divisor (�ndice do pivot que divide o array em particoes)

# $t0 - pivot, $t1 - limite de menores ou iguais ou pivot
# $t2 - indice para percorrer sub-array
	sll  $t0, $a2, 2	# multiplica por 4
	add  $t0, $t0, $a0	# calcula endereco do pivot
	lw   $t0, 0($t0)	# armazena pivot 
	
	addi $t1, $a1, -1	# inicializa vari�vel do limite de menores ou iguais
	add  $t2, $a1, $zero	# inicializa indice com primeira posicao do sub array
	
particao_loop:
	slt  $t3, $t2, $a2	# enquanto indice < �ltimo ind.
	beq  $t3, $zero, end_particao
	
	sll  $t3, $t2,  2	# multiplica indice por 4
	add  $t3, $t3, $a0	# calcula endereco da posicao no array
	lw   $t4, 0($t3)	# carrega elemento do array
	
	sle  $t5, $t4, $t0	# testa se � menor ou igual ao pivot
	beq  $t5, $zero, continue_particao_loop # se � maior, continua loop
	addi $t1, $t1, 1	# sen�o, incrementa limite de menores ou iguais, pois achou um novo menor ou igual

# faz swap
	sll  $t5, $t1, 2
	add  $t5, $t5, $a0	# calcula endere�o em memoria do limite de menores ou iguais
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


###########################################################################################
###########################################################################################
###########################################################################################

insertion_sort:
	#$a0 = base do array de inteiros    $a1 = numero de elementos no array de inteiros
	add $t0, $a0, $zero
	
	li $v0, 4
	la $a0, insertion_sort_msg
	syscall
	
	add $a0, $t0, $zero
	
	addi $t0, $zero, 1 
	add $t1, $zero, $zero
	add $t2, $zero, $zero
	add $t3, $zero, $a1
	# $t0 = i   $t1 = j   $t2 = v   $t3 = fim
	
loop_insertion:
	slt $t4, $t0, $t3 # verifica se i < fim
	beq $t4, $zero, back # senão sai do loop
	
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
	beq $t4, $zero, back # if j <= 0, termina loop
	
	addi $t4, $t1, -1 # $t4 = j - 1
	sll $t4, $t4, 2 # faz (j-1) * 4 para calcular a posição do array
	add $t5, $t4, $a0 #calcula posição do array
	lw $t5, 0($t5) # pega A[j-1]
	slt $t4, $t2, $t5 # verifica se v < A[j-1]
	beq $t4, $zero, back # se não for, termina o loop
	
	sll $t4, $t1, 2  # faz j * 4 para calcular a posição do array
	add $t4, $t4, $a0 #calcula posição de A[j]
	sw $t5, 0($t4) #salva A[j-1] em A[j]
	addi $t1, $t1, -1 # j--
	
	j loop_to_move_insertion

back:
	jr $ra
####################################################################
####################################################################

convert_to_byte_array:
	add $a0, $s1, 1		# carrega argumento para funcao de alocacao de memoria, o numero de bytes a serem alocados
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	jal allocate_memory	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	

	add $t0, $zero, $zero 	# inicializa contador, para deslocamento no array de inteiro
	add $t1, $zero, $zero	# inicializa contador, para deslocamento no array de bytes
	add $t2, $v0, $zero	# inicializa vari�vel para armazenar a string a ser escrita
	add $s0, $v0, $zero
convert_to_byte_array_loop:
	beq $t0, $s4, end_convert_to_byte_array	# se � do tamanho do array de inteiros, termina
	sll $t3, $t0, 2		# multiplica por 4, endere�amento por word
	add $t3, $t3, $s2	# calcula o endere�o do elemento atual do array
		
	lw  $t3, 0($t3)		# carrega o elemento, o inteiro no caso
	
	slt $t4, $t3, $zero	# testa se eh negativo
	bne $t4, 1, convert_int	# se nao eh, continua

	mul  $t3, $t3, -1	# se eh torna positivo
	add  $t5, $zero, 45	# adiciona hifen para negativo
	add  $t6, $s0, $t1	# carrega endereco + deslocamento em array de bytes
	sb   $t5, 0($t6)	# escreve hifen em array de bytes
	addi $t1, $t1, 1	# incrementa deslocamento para prox. posicao
	
convert_int:
	li  $t5, 10	
	
	slt $t6, $t3, $t5	# se � menor que 10, nada a fazer aqui
	beq $t6, 1, write_space
	
	div  $t3, $t5		# divide por 10 e poe em lo o quociente e em hi o resto
	
	mflo $t5		# carrega o quociente, prox valor de casa decimal a ser escrita
	
	add  $t6, $s0, $t1	# calcula endereco do prox. byte a ser escrito			
	addi $t5, $t5, 48	# adiciona base do ASCII
	sb   $t5, 0($t6)	# poe no array
	add  $t1, $t1, 1	# incrementa deslocamento do array de byte
	
	mfhi $t3
	j convert_int
	
write_space:
	add  $t6, $s0, $t1	# calcula endereco do prox. byte a ser escrito
	addi $t5, $t3, 48	# ultimo digito a ser escrito
	sb   $t5, 0($t6)	# escreve ultimo digito
	add  $t6, $t6, 1	# calcula endereco do prox. byte a ser escrito

	addi $t5, $zero, 32     # whitespace
	sb   $t5, 0($t6)	# escreve espaco em branco, o divisor de numeros																													
	
	addi $t1, $t1, 2	# incrementa deslocamento no array de byte
	addi $t0, $t0, 1	# incrementa deslocamento no array de inteiro
	
	j convert_to_byte_array_loop

end_convert_to_byte_array:
	add  $t6, $t6, 1	# calcula endereco do prox. byte a ser escrito
	add  $t5, $zero, $zero  # terminator
	sb   $t5, 0($t6)	# escreve espaco em branco, o divisor de numeros
	jr   $ra
############################################################################3
write_file:
	la   $a0, file_name	# Carrrega nome do arquivo
	addi $a1, $zero, 9	# Abre o arquivo para no modo de append
	li   $v0, 13		# chamada de sistema para abrir o arquivo
	syscall
	
	add $t0, $v0, $zero	# salva o descritor de arquivo	
	
	addi $a0, $zero, 4	# inicializa argumento, numero de bytes a serem alocados
	li   $v0, 9		# chamada para alocar $a0 bytes no heap de memoria
	syscall
	
	addi $t1, $zero, 13 	# Come�a quebra de linha x2
	sb   $t1, 0($v0)
	sb   $t1, 2($v0)
	addi $t1, $zero, 10
	sb   $t1, 1($v0)
	sb   $t1, 3($v0)
	
	add  $a0, $t0, $zero	
	add  $a1, $v0, $zero
	addi $a2, $zero, 4
	li   $v0, 15
	syscall	
	
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	li  $v0, 15
	syscall	
	
	li  $v0, 16
	syscall
	jr $ra
	
