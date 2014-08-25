#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>
#include "ep2_utils.h"

void insertion_sequencial( int* array, int left, int right ) {
    int i, j, v;
    int size = right - left + 1;

	for (i = left; i < size; i++) 
	{
		v = array[i];
		j = i;

		while ( (j > left) && (array[j - 1] > v) ) 
		{
			array[j] = array[j - 1];
			j = j - 1;
		}
		array[j] = v;
	}
}

void insertion_paralelo (int* array, int left, int right ) {
	int id, start, end, total_threads, array_thread_size;
	int size = right - left + 1;

	#pragma omp parallel shared( size, total_threads, array_thread_size ) private( start, end ) 
	{
		total_threads = omp_get_num_threads();
		array_thread_size = size / total_threads;
		
		int id = omp_get_thread_num();
		start = id * array_thread_size;
		end = start + array_thread_size - 1;
		if(id == total_threads - 1) {
			printf("Thread %d ordering from %d to %d\n", id, start, size-1);
			insertion_sequencial( array, start, size - 1 );
		}
		else {
			printf("Thread %d ordering from %d to %d\n", id, start, end);
			insertion_sequencial( array, start, end );
		}
	}
	
	insertion_sequencial( array, 0, size - 1 );
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
	printf("\nInsertion Sort Sequencial:\nOrdering %d elements\n", (int)size);
	start = omp_get_wtime();
	insertion_sequencial(array, 0, size - 1);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	free(array);		

	array = read_int_array( file_name, &size );
	printf("\nInsertion Sort Paralelizado:\nOrdering %d elements\n", (int)size);
	start = omp_get_wtime();
	insertion_paralelo ( array, 0, size - 1 );
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	fast_check_array_is_sorted( file_name, array, size );

	// write_file(file_name, size, array);
	free(array);	

	exit( EXIT_SUCCESS );
}