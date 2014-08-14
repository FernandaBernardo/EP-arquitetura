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

	for (i = start; i <= end; i++) {
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
	int start, end, total_threads, array_size;
	
	#pragma omp parallel shared( total_threads, array_size ) private( start, end ) 
	{
		int id = omp_get_thread_num();
		total_threads = omp_get_num_threads();
		
		array_size = size/total_threads;
		
		start = id*array_size;
		end = start+array_size-1;

		if(id == total_threads-1) {
			insertion_paralelo(array, start, size - 1);
		}
		else {
			insertion_paralelo(array, start, end);
		}
	}
	
	insertion_paralelo(array, 0, size - 1);
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
	// imprime_array(array, size);
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