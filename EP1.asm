.data
new_line:           	# nova linha, para prints - facilita debug
    	.asciiz "\n"
new_space:           	# novo espaço, para prints - facilita debug
    	.asciiz " "
byte_array_ended:	# msg para print ao terminar de printar um array de bytes - facilita debug
	.asciiz "Fim do array de bytes\n"
bytes_readed:		# msg para print - facilita debug
	.asciiz "Número de bytes lidos: "
int_array_ended:	# msg para print - facilita debug
	.asciiz "Fim do array de inteiros\n"
int_readed:
	.asciiz "Número de inteiros convertidos: "
fin:                	# arquivo para entrada
    	.asciiz "testin.txt"
array:
	.align 2
	.space 1024
min_size:
	.word 256		# número inicial de bytes a serem lidos do arquivo
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
# Retorna em $v0 o endereço para o nome do arquivo. Deve usar do dialog para input
	la $v0, fin
	jr $ra

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
	# É esperado que $a0 contenha o endereço para o nome do arquivo
	li   $a1, 0     	# parâmetro para abrir para leitura (0: leitura, 1: escrita)
	syscall         	# syscall: abre arquivo e armazena em $v0 o descritor de arquivo
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
	syscall             	# syscall: lê no máx. $a2 bytes do arquivo e armazena em $v0 a qtde de bytes lidas de fato

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
	
close_file:
	#Antes de fechar o arquivo, armazena em $s1 o número de bytes lidos na última iteração
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
    
print_byte_array: 
    	add $a0, $s0, $zero	# carrega endereço da posição inicial do array de bytes que contém o arquivo
    	li $v0, 4		# carrega comando para print, considerando o endereço em $a0 como uma string
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
# converte o array de bytes cujo endereço base está em $s0 em um array de inteiros
# ignora bytes que definam espaçamento ou quebra de linha (tanto em windows como em unix)
# armazena o endereço base do array de inteiros resultantes em $s2
# o array de inteiros resutante tem o mesmo tamanho que o valor que $s1 possuir
	add $t0, $s0, $zero   		# pega o endereço base do array de bytes 
	add $t1, $zero, $zero   	# inicia contador de leitura
	add $t2, $zero, $zero		# inicia contador de escrita
	add $t3, $zero, $zero		# inicia variável para inteiro lido
	
	add $a0, $s1, $zero		# carrega o número de bytes lidos do arquivo
	sll $a0, $a0, 2			# multiplica por 4 pois bytes serão convertidos para int, que ocupa 4 bytes
	li $v0, 9			# carrega chamada de sistema para alocação de memória
	syscall 			# syscall: aloca $a0 bytes e retorna endereço do primeiro em $v0
	add $s2, $v0, $zero		# salva em $s2 o endereço base do array de inteiros
	
conv_loop:
	beq  $s1, $t1, end_conv_loop	# se o valor do contador = número de bytes lidos do arquivo, termina loop de conversão
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
	
	beq $v0, 1, conv_loop		# se foi detectada nova linha no unix, deve ignorar 1 byte seguinte
					# pois é apenas caractere especial (Line Feed)

	addi $t1, $t1, 1		# incrementa contador, pois se detectou nova linha no windows, deve ignorar os 2 bytes seguintes
					# visto que no windows, são 2 bytes para nova linha = (CR)(LF)
	beq  $v0, 2, conv_loop
	
	addi $t1, $t1, -2		# senão detectou em nenhum cenário, volta contador pro estado inicial antes desses testes
					

convert_byte:	
# $t0 = endereço base do array de bytes, $t1 = contador de leitura, $t2 = contador de escrita, 
# $t3 = var para o inteiro sendo construído, $t5 = último byte lido
# $s2 = endereço base do array de inteiros
	addi $t1, $t1, 1    	# incrementa contador de leitura
	
	beq  $t5, 32, add_int	# verifica se é espaço, se for adiciona o inteiro lido até agora
	addi $t5, $t5, -48	# senão, subtrai 48 para converter de ASCII para int
	
	mul  $t3, $t3, 10	# avança casa decimal na variável a ser escrita no array
	add  $t3, $t3, $t5	# soma o a unidade atual

	j conv_loop		# continua o loop
    
add_int:
	sll $t6, $t2, 2		# multiplica por 4
	add $t6, $t6, $s2	# soma deslocamento (contador de escrita) ao endereço base do array de inteiro
	sw  $t3, 0($t6)		# armazena inteiro construído da posição calculada

	add $t3, $zero, $zero	# zera valor da var para inteiro sendo construído
	addi $t2, $t2, 1 	# incrementa contador de escrita 
	j conv_loop		

end_conv_loop:
	add $s4, $t2, $zero	# armazena em $s4 o número de inteiros escritos
	jr $ra  

print_int_array:
# $s2 = endereço base do array de inteiros, $s4 = número de inteiros escritos no array
	add $t0, $zero, $zero	# inicia contador
loop_print_int_array:
	beq $t0, $s4, end_print_int_array
	sll $t1, $t0, 2
	add $t1, $t1, $s2
	lw  $a0, 0($t1)
	li $v0, 1
	syscall
	la $a0, new_space	# imprime espaço
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
	
	
	
	
