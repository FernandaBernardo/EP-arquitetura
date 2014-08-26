/*
	QUICKSORT 
	Roda apenas o paralelizado. O sequencial pode ser rodado descomentando as linhas de código em main().

Renan Souza de Freitas 		7629870
Fernanda Moraes Bernardo	7971991
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <time.h>
#include "ep2_utils.h"

void swap( int* a, int* b) {
	int temp = *a;
	*a = *b;
	*b = temp;
}

int median_of_three_pivot(int* array, unsigned int start, unsigned int end){

	unsigned int middle = end+start/2;

	int x = array[start];
	int y = array[middle];
	int z = array[end];

	if( x < y ) {
		
		if( y < z) return middle;
		return end;

	} else if ( x < z) return start;

	return end;
}

int partition_quicksort(int* array, int left, int right) {
	
	int pivot_position = median_of_three_pivot( array, left, right );
	int pivot = array[ pivot_position ]; 
	swap( array + pivot_position, array + right );

	int i, j;
	i = left - 1;

	for (j = left; j <= right - 1; ++j) {
		if (array[j] <= pivot) {
			i++;
			swap( array + i, array + j );
		}
	}

	swap( array + i + 1, array + right );
	return i + 1;
}

/*
Retorna a posicao de insercao do pivo no array passado.
*/
int parallel_partition_quicksort( int* array, int pivot, int left, int right ) {
	
	int i, j;

	i = left - 1;

	for (j = left; j <= right; ++j) {
		if (array[j] <= pivot) {
			i++;
			swap( array + i, array + j );
		}
	}

	return i + 1;
}

void sequential_quicksort (int* array, int left, int right) {
	if (left < right) {
		int q = partition_quicksort(array, left, right);
		sequential_quicksort(array, left, q - 1);
		sequential_quicksort(array, q + 1, right);
	}
}


static size_t MIN_SIZE = 2001;

void parallel_quicksort (int* array, int left, int right ) {
	if ( left < right) {
		if( right - left + 1 < MIN_SIZE) 
		{	
			sequential_quicksort( array, left, right );

		} else {

			int q = partition_quicksort( array, left, right );
			int left_size = q - left;
			int right_size = right - q + 2;
			int seq_left, seq_right;
			seq_left = seq_right = 0;
			
			if (  left_size < MIN_SIZE ) 
			{
				sequential_quicksort( array, left, q-1);
				seq_left = 1;
			} 
			
			if( right_size < MIN_SIZE )
			{
				sequential_quicksort( array, q+1, right );
				seq_right = 1;
			} 

			#pragma omp parallel shared( seq_left, seq_right, left, right, q )
			{
				#pragma omp single nowait
				{
					if( ! seq_left )
						parallel_quicksort( array, left, q - 1 );
				}
	
				#pragma omp single nowait
				{
					if( ! seq_right)
						parallel_quicksort( array, q + 1, right ); 
				}
			}
		}		
	} 
}

static double call_function( const char* msg, const char* file_name, void (*quicksort) ( int* array, int start, int end ), int check_sorted ){
	
	size_t size;
	int* array;
	double start, elapsed_time;
	array = read_int_array( file_name, &size );

	printf("\n\n\n%s:\nOrdering %d elements\n", msg, (int)size);
	// print_indexed_array_from( array, 0, size - 1);

	start = omp_get_wtime();
	(*quicksort)(array, 0, size - 1);
	elapsed_time = omp_get_wtime() - start;

	printf("Elapsed time: %f sec.\n\n", elapsed_time);

	if( check_sorted ) {
		fast_check_array_is_sorted( file_name, array, size );
	}
	free( array );
	
	return elapsed_time;
}

int main(int argc, char *argv[]) {
	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	
	
	// double sequential_time, parallel_time = 0.0;
	// sequential_time = call_function( "Sequential QuickSort", argv[1], sequential_quicksort, 0 );

	// double start, elapsed_time;

	size_t size;
	int* array;
	const char* file_name = argv[1];
	array = read_int_array( file_name, &size );
	// printf("\n\n\n%s:\nOrdering %d elements\n", "Parallel QuickSort", (int)size);
	// parallel_time = call_function( "Parallel QuickSort", argv[1], parallel_quicksort, 1 );

	omp_set_nested(1);
	parallel_quicksort(array, 0, size - 1);

	// fast_check_array_is_sorted( file_name, array, size );

	write_file ( file_name, size, array);
	
	free( array );
		
	// printf("\n\nRESULT:\nElapsed seq. time: %f sec.\nElapsed par. time: %f sec.\n", sequential_time, parallel_time);
  	// stream = freopen("CON", "w", stdout);
	exit( EXIT_SUCCESS );
}