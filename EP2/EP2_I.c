#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>
#include "ep2_utils.h"

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

int main(int argc, char const *argv[])
{
	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	size_t size;
	int* array;
	const char* file_name = argv[1];
	double start, end, sequential_time, parallel_time;


	array = read_int_array( file_name, &size );
	printf("\nInsertion Sort Sequencial:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	insertion_sequencial(array, 0, size - 1 );
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	// check_array_is_sorted( array, size );
	free(array);		

	array = read_int_array( file_name, &size );
	printf("\nInsertion Sort Paralelizado:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	insertion_paralelo(array, size);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	// check_array_is_sorted( array, size );
	free(array);		

	exit( EXIT_SUCCESS );
}