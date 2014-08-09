#include <stdio.h>
#include <omp.h>

int main(int argc, char *argv[]) {
	printf("\n Olá 1 - Fora da Região Paralela \n\n");

	#pragma omp parallel
	{
		int id = omp_get_thread_num();
		int nt = omp_get_num_threads();
		printf("Sou a thread %d de um total %d\n", id, nt);
	}
	printf("\n Olá 2 - Fora da Região Paralela \n\n");
	return 0;
}

//usar 'export OMP_NUM_THREADS=X' onde X é o número 
//de threads que você quer usar