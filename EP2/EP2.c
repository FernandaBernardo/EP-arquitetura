#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>

#define false 0
#define true 1

//Variáveis globais
size_t int_array_size = 0;

/* Imprime de 10 em 10 elementos do array */
void imprime_array(int* array, size_t size) {
	int i;
	for (i = 0; i < size; i++) {
		// if( i!=0 && i%10 == 0 ){
			// printf("\n");
		// }
		printf("%d ", array[i]);
	}
	printf("\n-----\n");
}

/* Imprime de 10 em 10 elementos do array */
void imprime_array_from(int* array, int start, int end) {
	int i;
	for (i = start; i <= end; i++) {
		// if( i!=0 && i%10 == 0 ){
			// printf("\n");
		// }
		printf("%d ", array[i]);
	}
	printf("\n-----\n");
}

/* Expande original, um array de int, do tamanho original para um novo tamanho, que deve ser maior que o original */
int* expand_array( int* original, size_t original_size, size_t new_size ){
	if( original_size > new_size ){
		fprintf( stderr, "ERROR: Argumento invalido. O novo tamanho do array deve ser maior que o antigo.\n");
		exit( EXIT_FAILURE );
	}

	int* expanded_array;

	if( original_size > (new_size - original_size) ){
		
		expanded_array = (int*)realloc( original, new_size);
		
		if( expanded_array == NULL ){
			fprintf( stderr, "ERROR: Memoria insuficiente para alocar array expandido.\n" );
			exit( EXIT_FAILURE );
		}

		int index;
		for( index = new_size - original_size; (index < new_size); index++){
			expanded_array[index] = 0;
		}		
	
	} else {

		expanded_array = (int*)calloc(new_size, sizeof(int));
	
		if( ! expanded_array ){
			fprintf( stderr, "ERROR: Memoria insuficiente para alocar array expandido.\n" );
			exit( EXIT_FAILURE );
		}

		int index;
		for( index = 0; index < original_size; index++){
			expanded_array[index] = original[index];
		}	
	}

	return expanded_array;
}

int* le_array_inteiros( char*  nome_arquivo, size_t* size ) {
	printf("Reading input file %s\n", nome_arquivo );
	FILE *entrada = fopen( nome_arquivo, "rb" );
	
	if ( entrada == NULL ) {
		fprintf(stderr, "ERROR: Arquivo não encontrado!\n");
		exit(EXIT_FAILURE);
	};

	rewind( entrada );

	int index = 0;
	size_t array_size = 10;
	int *array = (int*)malloc(sizeof(int)*array_size);
	
	if( array == NULL){
		int size_to_print = array_size;
		fprintf(stderr, "ERROR: Memoria insuficiente para alocar array de %d inteiros. \n", size_to_print);
		exit(EXIT_FAILURE);
	}

	while( ! feof( entrada ) ){


		int aux = 0;
		if(  fscanf( entrada, "%d", &aux ) < 1 ){
			break;
		}
		
		if( index == array_size ){
			size_t original_size = array_size;
			array_size = array_size * 2;
		
			int* expanded_array = expand_array( array, original_size, array_size);
			free(array);
			array = expanded_array;
		}

		array[index] = aux;
		index++;
	}

	fclose(entrada);
	
	(*size) = index+1;

	printf("%s was read.\n", nome_arquivo);
	return array;
}

void insertion_sequencial (int A[], int tam) {
	int i, j, v;

	for (i = 1; i < tam; i++) {
		v = A[i];
		j = i;
		while ((j > 0) && (A[j - 1] > v)) {
			A[j] = A[j - 1];
			j = j - 1;
		}
		A[j] = v;
	}
}

int partition_quicksort(int A[], int esquerdo, int direito) {
	int x, i, j, temp;

	x = A[direito]; // pivo
	i = esquerdo - 1;

	for (j = esquerdo; j <= direito - 1; ++j) {
		if (A[j] <= x) {
			i++;
			// trocar
			temp = A[i];
			A[i] = A[j];
			A[j] = temp;
		}
	}

	// reposicionar o pivo
	temp = A[i + 1];
	A[i + 1] = A[direito];
	A[direito] = temp;
	return (i + 1);
}

void quick_sequencial (int A[], int esquerdo, int direito) {
	if (esquerdo < direito) {
		int q = partition_quicksort(A, esquerdo, direito);
		quick_sequencial(A, esquerdo, q - 1);
		quick_sequencial(A, q + 1, direito);
	}
}

void parallel_quicksort (int A[], int left, int right) {
	if (left < right) {

		int q = partition_quicksort(A, left, right);

		if( ( right - (q+1) + 1 > 500) && ( (q-1) - left + 1> 500) ) {

			#pragma omp parallel sections
			{	
				#pragma omp section
				{
					parallel_quicksort(A, left, q - 1);
				}

				#pragma omp section
				{
					parallel_quicksort(A, q + 1, right);
				}
			}
		} else {
			quick_sequencial(A, left, q - 1);
			quick_sequencial(A, q + 1, right);
		}
	}
}

void check_array_is_ordered(int* array, size_t size){
	int i;
	for (i = 1; i < size; i++)
	{
		if(array[i-1] > array[i]){
			printf("Wrong: %d antes de %d \n", array[i-1], array[i]);
		}
	}

}

int main(int argc, char *argv[]) {

	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	size_t size;
	char* file_name = argv[1];
	int* array;

	// array = le_array_inteiros( file_name, &size );
	// printf("\nInsertion Sort Sequencial:\n");
	// imprime_array(array, size);
	// insertion_sequencial(array, size );
	// imprime_array(array, size);
	// check_array_is_ordered( array, size );
	// free(array);

	double start, end;
	array = le_array_inteiros( file_name, &size );
	printf("\nQuick Sort Sequencial:\n");
	// imprime_array(array, size);
	start = omp_get_wtime();
	quick_sequencial(array, 0, size - 1);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	check_array_is_ordered( array, size );
	free(array);


	array = le_array_inteiros( file_name, &size );
	printf("\nQuick Sort Paralelizado:\n");
	// imprime_array(array, size);
	start = omp_get_wtime();
	parallel_quicksort(array, 0, size - 1);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	check_array_is_ordered( array, size );
	free(array);

	exit( EXIT_SUCCESS );
}