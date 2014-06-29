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
	.asciiz "N�mero de inteiros convertidos: "
file_name_input:
	.asciiz "Digite o nome do seu arquivo: "
file: #nome do arquivo que será colocado pelo usuário
	.ascii ""
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
	j exit

exit:
# Termina o programa
    	li $v0,10       #fim
	syscall

get_file_name:
# Retorna em $v0 o endere�o para o nome do arquivo. Deve usar do dialog para input
	li $v0, 54 #carrega chamada de sistema para mostrar um dialog para input de string
	la $a0, file_name_input #carrega a mensagem a ser mostrada no dialog
	la $a1, file #carrega o local onde será armazenado o input do usuário
	lw $a2, min_size #carrega o número de bytes que será lido
	syscall #coloca em $a1 o valor do status(0: OK status. -2: Cancel. -3: input.vazio. -4: tamanho do input é maior)
	
	bne $a1, $zero, exit #se o status foi diferente de 0, sai do programa
	
	la $v0, file #carrega o nome do arquivo em $a0
	
    li $t0, 0       #inicializando contador do loop para limpar o nome do arquivo e tirar o caracter que determina o final da string que não serve quando for usar para abrir o arquivo
    li $t1, 21      #inicializando o final do loop
    
file_name_clean:
    beq $t0, $t1, back_process #verifica se o loop chegou ao final
    lb $t3, file($t0) #pega o byte de determinada posição do nome do arquivo
    bne $t3, 0x0a, add_cont #verifica se esse byte contém o caracter 10 (0xa) (linefeed)
    sb $zero, file($t0) #se for igual ao caracter 10, substitui ele por zero
add_cont:
    addi $t0, $t0, 1 #adiciona um ao contador
	j file_name_clean
back_process:
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
	#Antes de fechar o arquivo, armazena em $s1 o n�mero de bytes lidos na �ltima itera��o
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
	add $t0, $s0, $zero   		# pega o endere�o base do array de bytes 
	add $t1, $zero, $zero   	# inicia contador de leitura
	add $t2, $zero, $zero		# inicia contador de escrita
	add $t3, $zero, $zero		# inicia vari�vel para inteiro lido
	
	add $a0, $s1, $zero		# carrega o n�mero de bytes lidos do arquivo
	sll $a0, $a0, 2			# multiplica por 4 pois bytes ser�o convertidos para int, que ocupa 4 bytes
	li $v0, 9			# carrega chamada de sistema para aloca��o de mem�ria
	syscall 			# syscall: aloca $a0 bytes e retorna endere�o do primeiro em $v0
	add $s2, $v0, $zero		# salva em $s2 o endere�o base do array de inteiros
	
conv_loop:
	beq  $s1, $t1, end_conv_loop	# se o valor do contador = n�mero de bytes lidos do arquivo, termina loop de convers�o
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
	
	beq $v0, 1, conv_loop		# se foi detectada nova linha no unix, deve ignorar 1 byte seguinte
					# pois � apenas caractere especial (Line Feed)

	addi $t1, $t1, 1		# incrementa contador, pois se detectou nova linha no windows, deve ignorar os 2 bytes seguintes
					# visto que no windows, s�o 2 bytes para nova linha = (CR)(LF)
	beq  $v0, 2, conv_loop
	
	addi $t1, $t1, -2		# sen�o detectou em nenhum cen�rio, volta contador pro estado inicial antes desses testes
					

convert_byte:	
# $t0 = endere�o base do array de bytes, $t1 = contador de leitura, $t2 = contador de escrita, 
# $t3 = var para o inteiro sendo constru�do, $t5 = �ltimo byte lido
# $s2 = endere�o base do array de inteiros
	addi $t1, $t1, 1    	# incrementa contador de leitura
	
	beq  $t5, 32, add_int	# verifica se � espa�o, se for adiciona o inteiro lido at� agora
	addi $t5, $t5, -48	# sen�o, subtrai 48 para converter de ASCII para int
	
	mul  $t3, $t3, 10	# avan�a casa decimal na vari�vel a ser escrita no array
	add  $t3, $t3, $t5	# soma o a unidade atual

	j conv_loop		# continua o loop
    
add_int:
	sll $t6, $t2, 2		# multiplica por 4
	add $t6, $t6, $s2	# soma deslocamento (contador de escrita) ao endere�o base do array de inteiro
	sw  $t3, 0($t6)		# armazena inteiro constru�do da posi��o calculada

	add $t3, $zero, $zero	# zera valor da var para inteiro sendo constru�do
	addi $t2, $t2, 1 	# incrementa contador de escrita 
	j conv_loop		

end_conv_loop:
	add $s4, $t2, $zero	# armazena em $s4 o n�mero de inteiros escritos
	jr $ra  

print_int_array:
# $s2 = endere�o base do array de inteiros, $s4 = n�mero de inteiros escritos no array
	add $t0, $zero, $zero	# inicia contador
loop_print_int_array:
	beq $t0, $s4, end_print_int_array
	sll $t1, $t0, 2
	add $t1, $t1, $s2
	lw  $a0, 0($t1)
	li $v0, 1
	syscall
	la $a0, new_space	# imprime espa�o
	li $v0, 4
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