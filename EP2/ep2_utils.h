#ifndef EP2_UTILS_H
#define EP2_UTILS_H

#define false 0
#define true 1

/* Imprime em linha os elementos do array */
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

/* Imprime em linha os elementos do array */
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

int* read_int_array( const char*  nome_arquivo, size_t* size ) {
	FILE *entrada = fopen( nome_arquivo, "rb" );
	
	if ( entrada == NULL ) {
		perror("ERROR: an error occurred while opening the input file :\n");
		exit(EXIT_FAILURE);
	};

	rewind( entrada );

	int index = 0;
	size_t array_size = 10;
	int *array = (int*)malloc(sizeof(int)*array_size);
	
	if( array == NULL){
		int size_to_print = array_size;
		fprintf(stderr, "ERROR: Memoria insuficiente para alocar array de %d inteiros. \n", size_to_print);
		perror("Error message:");
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

/* 
Testa se o array do argumento está ordenado de forma crescente. 
O teste tem complexidade de O(n^2), então é bem custoso para arrays grandes.
Deve ser usado quando não faz diferença o tempo de execução pro usuário.
*/
void check_array_is_sorted(int* array, size_t size){
	printf("Sanity test: checking if array is sorted...\n");
	double start = omp_get_wtime();
	
	int i, j;
	#pragma omp parallel for private(i,j)
	for (i = size-1; i > -1; i--)
		for(j=0; j < i ; j++ )
			if( array[j] > array[i] )
				printf("Wrong: %d antes de %d \n", array[j], array[i]);

	printf("Sanity test: sort checking has ended.\n");
	printf("Elapsed time testing: %f sec.\n", omp_get_wtime() - start );
}


#endif