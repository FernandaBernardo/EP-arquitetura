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
	
	unsigned int pivot_position;
	pivot_position = median_of_three_pivot( array, left, right );
	// pivot_position = right;

	int x = array[right]; // pivo
	
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

void sequencial_quicksort (int* array, int left, int right) {
	if (left < right) {
		int q = partition_quicksort(array, left, right);
		sequencial_quicksort(array, left, q - 1);
		sequencial_quicksort(array, q + 1, right);
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

void insertion_sequencial (int* array, int start, int end) {
	int i, j, v;

	for (i = start + 1; i <= end; i++) {
		v = array[i];
		j = i;
		while ((j > start) && (array[j - 1] > v)) {
			array[j] = array[j - 1];
			j = j - 1;
		}
		array[j] = v;
	}
}


void parallel_quicksort (int* array, int left, int right ) {
	if (left < right) {
		
		// printf("parallel_quicksort thread %d\n", omp_get_thread_num());
		int q = parallel_partition_quicksort(array, left, right);
		// #pragma omp sections
		{	
			// #pragma omp section
			{
				parallel_quicksort(array, left, q - 1 );
			}

			// #pragma omp section
			{
				parallel_quicksort(array, q + 1, right);
			}
		}
	}
}

void parallel_iteractive_quicksort ( int* array, int start, int end ) {
	int size = end - start + 1;

	if ( size == 0 || size == 1) {
		return;
	}

	int* stack = malloc(sizeof(int)*size*4);

	stack[0] = 0;
	stack[1] = size - 1;

	int stack_index;

	for ( stack_index = 1 ; stack_index >= 0; ) {
		
		int right, left;
		
		right = stack[ stack_index ]; 		//pop
		left =  stack[ stack_index - 1 ]; 	//pop
		
		stack_index -= 2; 			//remove

		if ( left < right ) {

			int q = parallel_partition_quicksort( array, left, right );

				stack[ stack_index + 1 ] = left;
				stack[ stack_index + 2 ] = q - 1;
				stack[ stack_index + 3 ] = q + 1;
				stack[ stack_index + 4 ] = right;

				stack_index += 4;
		}
	}

}

static double call_function( const char* msg, const char* file_name, void (*quicksort) ( int* array, int start, int end ), int check_sorted ){
	
	size_t size;
	int* array;
	double start, elapsed_time;
	array = read_int_array( file_name, &size );

	printf("\n\n\n%s:\nOrdering %d elements\n", msg, (int)size);

	start = omp_get_wtime();
	(*quicksort)(array, 0, size - 1);
	elapsed_time = omp_get_wtime() - start;

	printf("Elapsed time: %f sec.\n\n", elapsed_time);

	if( check_sorted ) {
		check_array_is_sorted( array, size );
	}

	free( array );
	
	return elapsed_time;
}

int main(int argc, char *argv[]) {
	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	
	double sequential_time, parallel_time;
	sequential_time = call_function( "Sequential QuickSort", argv[1], sequencial_quicksort, 0 );
	// parallel_time = call_function( "Parallel QuickSort", argv[1], parallel_quicksort, 0 );
	parallel_time = call_function( "Iteractive Parallel QuickSort", argv[1], parallel_iteractive_quicksort, 0 );
		
	printf("\n\nRESULT:\nElapsed seq. time: %f sec.\nElapsed par. time: %f sec.\n", sequential_time, parallel_time);

	exit( EXIT_SUCCESS );
}