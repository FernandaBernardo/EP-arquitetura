#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>

#define false 0
#define true 1
#define QUICK_INSERTION 1

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

/* 
Expande original, um array de int, do tamanho original para um novo tamanho, 
que deve ser maior que o original 
*/
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

int* read_int_array( char*  nome_arquivo, size_t* size ) {
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

	while( true ){


		int aux = 0;
		int read_elements = fscanf( entrada, "%d", &aux );

		if(  read_elements < 1 || feof( entrada )){
			break;
		}

		if( ferror( entrada )){
			perror( "ERROR: An error ocurred while reading input file: ");
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
	
	(*size) = index;

	return array;
}

void insertion_sequencial (int A[], int start, int end) {
	int i, j, v;

	for (i = start + 1; i <= end; i++) {
		v = A[i];
		j = i;
		while ((j > start) && (A[j - 1] > v)) {
			A[j] = A[j - 1];
			j = j - 1;
		}
		A[j] = v;
	}
}

void insertion_paralelo (int A[], int tam) {
	int i, j, v;

	#pragma omp for private (i, j, v)
	for (i = 1; i < tam; i++) {
		v = A[i];
		j = i;

		while ((j > 0) && (A[j - 1] > v)) {
			#pragma omp critical
			{
				A[j] = A[j - 1];
				j = j - 1;
			}
		}
		A[j] = v;
	}
}

int partition_quicksort(int A[], unsigned int esquerdo, unsigned int direito) {
	int x, temp;
	unsigned int i, j;

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
	unsigned int pivot_position = i + 1;
	temp = A[pivot_position];
	A[pivot_position] = A[direito];
	A[direito] = temp;
	return pivot_position;
}

void sequencial_quicksort (int A[], int esquerdo, int direito) {
	if (esquerdo < direito) {
		int q = partition_quicksort(A, esquerdo, direito);
		sequencial_quicksort(A, esquerdo, q - 1);
		sequencial_quicksort(A, q + 1, direito);
	}
}

int median_of_three_pivot(int A[], unsigned int start, unsigned int end){
	int middle, x, y, z;
	middle = end+start/2;

	x = A[start];
	z = A[end];
	y = A[middle];

	if( x < y ) {
		
		if( y < z) return middle;
		return end;

	} else if ( x < z) return start;

	return end;
}

int parallel_partition_quicksort(int* array, unsigned int left, unsigned int right) {
	int x, temp;
	unsigned int i, j, pivot_position;

	// pivot_position = median_of_three_pivot(array, left, right);// testar com outros valores de pivot
	pivot_position = right;
	// pivot_position = left + ( rand() % (right-left+1) );
	x = array[pivot_position]; // pivo
	i = left - 1;

	temp = array[right];
	array[right] = x;	
	array[pivot_position] = temp;

	// #pragma omp parallel for
	for (j = left; j <= right - 1; ++j) {
		if (array[j] <= x) {
			i++;
			// trocar
			temp = array[i];
			array[i] = array[j];
			array[j] = temp;
		}
	}

	// reposicionar o pivo
	pivot_position = i + 1;
	temp = array[pivot_position];
	array[pivot_position] = array[right];
	array[right] = temp;
	return pivot_position;
}

void internal_parallel_quicksort(int* array, int left, int right ) {
	if (left < right) {
		int q = parallel_partition_quicksort(array, left, right);

		internal_parallel_quicksort(array, left, q - 1 );
		internal_parallel_quicksort(array, q + 1, right);
	}
}

void parallel_quicksort (int* array, int left, int right ) {
	if (left < right) {

		int q = parallel_partition_quicksort(array, left, right);

		#pragma omp parallel sections
		{	
			#pragma omp section
			{
				internal_parallel_quicksort(array, left, q - 1 );
			}

			#pragma omp section
			{
				internal_parallel_quicksort(array, q + 1, right);
			}
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
	double start, end;

	if(QUICK_INSERTION){
	
		array = read_int_array( file_name, &size );
		printf("\nQuickSort Sequencial:\nOrdering %d elements\n", (int)size);
		// imprime_array(array, size);
		start = omp_get_wtime();
		sequencial_quicksort(array, 0, size - 1);
		end = omp_get_wtime();
		printf("Elapsed time: %f sec.\n\n", (end-start));
		// imprime_array(array, size);
		check_array_is_ordered( array, size );
		free(array);


		array = read_int_array( file_name, &size );
		printf("\nQuickSort Paralelizado:\nOrdering %d elements\n", (int)size);
		// imprime_array(array, size);
		start = omp_get_wtime();
		parallel_quicksort(array, 0, size - 1);
		end = omp_get_wtime();
		printf("Elapsed time: %f sec.\n\n", (end-start));
		// imprime_array(array, size);
		check_array_is_ordered( array, size );
		free(array);
		
	}

	// --------------------------------------------------------------------------------------------------

	if( !QUICK_INSERTION ){
		
		array = read_int_array( file_name, &size );
		printf("\nInsertion Sort Sequencial:\nOrdering %d elements\n", (int)size);
		// imprime_array(array, size);
		start = omp_get_wtime();
		insertion_sequencial(array, 0, size - 1 );
		end = omp_get_wtime();
		printf("Elapsed time: %f sec.\n\n", (end-start));
		// imprime_array(array, size);
		check_array_is_ordered( array, size );
		free(array);

		array = read_int_array( file_name, &size);
		printf("\nInsertion Sort Paralelizado:\nOrdering %d elements\n", (int)size);
		// imprime_array(array, size);
		start = omp_get_wtime();
		insertion_paralelo(array, size);
		end = omp_get_wtime();
		printf("Elapsed time: %f sec.\n\n", (end-start));
		// imprime_array(array, size);
		check_array_is_ordered( array, size );
		free(array);		

	}

	exit( EXIT_SUCCESS );
}