#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>
#include "ep2_utils.h"

int median_of_three_pivot(int* array, unsigned int start, unsigned int end){

	unsigned int middle = end+start/2;

	int x = array[start];
	int z = array[end];
	int y = array[middle];

	if( x < y ) {
		
		if( y < z) return middle;
		return end;

	} else if ( x < z) return start;

	return end;
}

int partition_quicksort(int* array, unsigned int left, unsigned int right) {
	
	unsigned int pivot_position = median_of_three_pivot(array, left, right);

	int x = array[pivot_position]; // pivo
	
	unsigned int i = left - 1;
	unsigned int j;
	int temp;

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

void sequencial_quicksort (int A[], int esquerdo, int direito) {
	if (esquerdo < direito) {
		int q = partition_quicksort(A, esquerdo, direito);
		sequencial_quicksort(A, esquerdo, q - 1);
		sequencial_quicksort(A, q + 1, direito);
	}
}

int parallel_partition_quicksort(int* array, unsigned int left, unsigned int right) {
	int x, temp;
	unsigned int i, j, pivot_position;

	pivot_position = median_of_three_pivot(array, left, right);// testar com outros valores de pivot
	// pivot_position = right;
	// pivot_position = left + ( rand() % (right-left+1) );
	x = array[pivot_position]; // pivo
	i = left - 1;

	temp = array[right];
	array[right] = x;	
	array[pivot_position] = temp;

	for (j = left; j <= right - 1; ++j) {
		if (array[j] <= x) {
			i++;
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


void parallel_quicksort (int* array, int left, int right ) {
	if (left < right) {
		
		if( right -left + 1 < 1000){
			insertion_sequencial(array, left, right );
		} else {
			// printf("parallel_quicksort thread %d\n", omp_get_thread_num());
			int q = parallel_partition_quicksort(array, left, right);
			#pragma omp sections
			{	
				#pragma omp section
				{
					parallel_quicksort(array, left, q - 1 );
				}

				#pragma omp section
				{
					parallel_quicksort(array, q + 1, right);
				}
			}
		}
	}
}

int main(int argc, char *argv[]) {
	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	size_t size;
	int* array;
	const char* file_name = argv[1];
	double start, end, sequential_time, parallel_time;
	


	array = read_int_array( file_name, &size );
	printf("\n\n\nSequential QuickSort:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	sequencial_quicksort(array, 0, size - 1);
	sequential_time = omp_get_wtime() - start;
	printf("Elapsed time: %f sec.\n\n", sequential_time);
	// imprime_array(array, size);
	// check_array_is_sorted( array, size );
	free( array );

	array = read_int_array( file_name, &size );
	printf("\n\nParallel QuickSort:\nOrdering %d elements\n", (int)size);
	// imprime_array(array, size);
	start = omp_get_wtime();
	omp_set_nested(1);
	omp_set_num_threads(2);
	parallel_quicksort(array, 0, size - 1);
	parallel_time = omp_get_wtime() - start;
	printf("Elapsed time: %f sec.\n\n", parallel_time);
	// imprime_array(array, size);
	// check_array_is_sorted( array, size );
	free(array);

	printf("\n\nRESULT:\nElapsed seq. time: %f sec.\nElapsed par. time: %f sec.\n", sequential_time, parallel_time);

	exit( EXIT_SUCCESS );
}