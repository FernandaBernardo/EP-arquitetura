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

int parallel_partition_quicksort( int* array, int pivot, int left, int right ) {
	
	int i, j;

	i = left - 1;

	for (j = left; j <= right; ++j) {
		if (array[j] <= pivot) {
			i++;
			swap( array + i, array + j );
		}
	}

	return i+1;
}

void sequential_quicksort (int* array, int left, int right) {
	if (left < right) {
		int q = partition_quicksort(array, left, right);
		sequential_quicksort(array, left, q - 1);
		sequential_quicksort(array, q + 1, right);
	}
}


struct thread_data
{
	int start;
	int q;
	int end;
};

void parallel_quicksort (int* array, int left, int right ) {
	if (left < right) {

		static unsigned int total_threads = 1;	
		// printf("total_threads = %d\n", total_threads);
		if( total_threads == omp_get_num_threads() || right - left + 1 < 1000) 
		{	
			int q = partition_quicksort(array, left, right);
			sequential_quicksort( array, left, q - 1 );
			sequential_quicksort( array, q + 1, right );
		} else {

			int pivot_position = median_of_three_pivot(array, left, right);
			int pivot = array[ pivot_position ];
			swap( array+pivot_position, array+right );

			struct thread_data *thread;

			int num_threads, t_size, t, t_i;	

			#pragma omp parallel shared( num_threads, pivot, thread, t_size )
			{
				int id = omp_get_thread_num();
				num_threads = omp_get_num_threads();
				
				t_size 	= right - left + 1  / num_threads;
				
				#pragma omp single
				{
					thread  = malloc(sizeof(struct thread_data) * num_threads);
				}

				thread[ id ].start  = id * t_size + left;
				thread[ id ].end 	= thread[ id ].start + t_size - 1;
				
				if(  id == omp_get_num_threads() - 1 && (right - left + 1)%2 == 0 ) {
					thread[ id ].end -= 1; // subtrai 1 se for a thread que contém o pivot e não tiver subtraído 1 antes
				} 

				thread[ id ].q = parallel_partition_quicksort( array, pivot, thread[id].start, thread[id].end ); 
			}

			#pragma omp parallel for private(t)
			for( t = 1; t < omp_get_num_threads(); t++ ) { //Se é single-thread, ok
				size_t block_size = thread[ t ].q - thread[ t ].start;
				int* swap_block = malloc(sizeof(int*)*block_size);
				
				if( swap_block == NULL ){
					perror("ERROR while malloc'ing: ");
					exit( EXIT_FAILURE );
				}
				memcpy( swap_block, array + thread[ 0 ].q, block_size );
				memcpy( array + thread[ 0 ].q, array + thread[ t ].start, block_size );
				memcpy( array + thread[ t ].start, swap_block, block_size );
				// for( t_i = thread[ t ].start; t_i <  thread[ t ].q ; t_i++ ) {
				// 	swap( array + thread[ 0 ].q,  array + t_i );
				// 	thread[ 0 ].q += 1;
				// }
				thread[ 0 ].q += block_size;

				swap( array+thread[ 0 ].q, array+right );
				total_threads++;
			}


			parallel_quicksort(array, left, thread[ 0 ].q - 1 );
			parallel_quicksort(array, thread[ 0 ].q + 1, right);

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
		
			int pivot_position = median_of_three_pivot(array, left, right);// testar com outros valores de pivot
			int pivot = array[ pivot_position ];
			swap( array+pivot_position, array+right );

			int q = parallel_partition_quicksort( array, pivot, left, right - 1 );
			swap( array+q, array+right );

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
	// imprime_array_from( array, 0, size - 1);

	start = omp_get_wtime();
	(*quicksort)(array, 0, size - 1);
	elapsed_time = omp_get_wtime() - start;

	printf("Elapsed time: %f sec.\n\n", elapsed_time);

	if( check_sorted ) {
		fast_check_array_is_sorted( file_name, array, size );
		// check_array_is_sorted( file_name, array, size );
	}
	// imprime_array_from( array, 0, size - 1);
	free( array );
	
	return elapsed_time;
}

int main(int argc, char *argv[]) {
	if( argc <= 1 ) {
		printf("ERROR: No input file\n");
		exit(EXIT_FAILURE);
	} 
	
	double sequential_time, parallel_time = 0.0;
	sequential_time = call_function( "Sequential QuickSort", argv[1], sequential_quicksort, 0 );
	// omp_set_nested(1);
	parallel_time = call_function( "Parallel QuickSort", argv[1], parallel_quicksort, 1 );
	// parallel_time = call_function( "Iteractive Parallel QuickSort", argv[1], parallel_iteractive_quicksort, 1 );
		
	printf("\n\nRESULT:\nElapsed seq. time: %f sec.\nElapsed par. time: %f sec.\n", sequential_time, parallel_time);

	exit( EXIT_SUCCESS );
}