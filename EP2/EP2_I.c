#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>
#include "ep2_utils.h"

void insertion_sequencial(int start, int array[], int size) {
    if (start < size) {
        int j;
        int aux = array[start];
 		
        for (j = start; j > 0 && array[j-1] > aux; j--)
            array[j] = array[j-1];
        array[j] = aux;

        insertion_sequencial(++start, array, size);
    }
}

void insertion_paralelo(int start, int array[], int size) {
    if (start < size) {
        int j;
        int aux = array[start];
 		
 		#pragma omp parallel private(j, aux)
 		{
        for (j = start; j > 0 && array[j-1] > aux; j--)
            array[j] = array[j-1];
        array[j] = aux;
    	}

        insertion_paralelo(++start, array, size);
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
	insertion_sequencial(0, array, size);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	check_array_is_sorted( array, size );
	free(array);		

	array = read_int_array( file_name, &size );
	printf("\nInsertion Sort Paralelizado:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	// insertion_paralelo(array, size);
	insertion_paralelo(0, array, size);
	end = omp_get_wtime();
	printf("Elapsed time: %f sec.\n\n", (end-start));
	// imprime_array(array, size);
	check_array_is_sorted( array, size );
	free(array);		

	exit( EXIT_SUCCESS );
}