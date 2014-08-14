#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>
#include "ep2_utils.h"

void insertion_sequencial(int* A, int size) {
    int i, j, v;

	for (i = 0; i < size; i++) {
		v = A[i];
		j = i;

		while ((j > 0) && (A[j - 1] > v)) {
			A[j] = A[j - 1];
			j = j - 1;
		}
		A[j] = v;
	}
}

void insertion_paralelo(int* A, int start, int end) {
   int i, j, v;

	for (i = start; i < end; i++) {
		v = A[i];
		j = i;

		while ((j > 0) && (A[j - 1] > v)) {
			A[j] = A[j - 1];
			j = j - 1;
		}
		A[j] = v;
	}
}

void divide_array (int* array, int size) {
	#pragma omp parallel num_threads(4)
	{
		int total_threads = omp_get_num_threads();
		int thread_atual = omp_get_thread_num();
		int tam_array = size/total_threads;
		int ini = thread_atual*tam_array;
		int fim = ini+tam_array-1;
		printf("%d - %d\n", ini, fim);

		if(thread_atual == total_threads-1) {
			printf("ULTIMA %d - %d\n", ini, size);
			insertion_paralelo(array, ini, size);
		}
		else {
			printf("MEIO %d - %d\n", ini, fim);
			insertion_paralelo(array, ini, fim);
		}
	}
}

int main(int argc, char const *argv[]) {
	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	size_t size;
	int* array;
	const char* file_name = argv[1];
	double start, end, sequential_time, parallel_time;

	array = read_int_array( file_name, &size );
	printf("\nInsertion Sort Paralelizado:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	// insertion_paralelo(array, size);
	divide_array(array, size);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	imprime_array(array, size);
	fast_check_array_is_sorted(file_name, array, size );
	// imprime_array(array, size);
	free(array);	

	array = read_int_array( file_name, &size );
	printf("\nInsertion Sort Sequencial:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	insertion_sequencial(array, size);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	fast_check_array_is_sorted(file_name, array, size );
	// imprime_array(array, size);
	free(array);		

	exit( EXIT_SUCCESS );
}