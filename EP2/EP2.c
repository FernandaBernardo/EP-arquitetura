#include <stdio.h>
#include <omp.h>

void imprime_array(int A[], int tam) {
	int i;
	for (i = 0; i < tam; i++) {
		printf("%d ", A[i]);
	}
	printf("\n");
}

void insertion_sequencial (int A[], int tam) {
	int i, j, v;

	for (i = 1; i < tam; i++) {
		v = A[i];
		j = i;
		while ((j > 0) && (A[j - 1] > v)) {
			A[j] = A[j - 1];
			j = j - 1;
		}
		A[j] = v;
	}
}

int particao_quick_sequencial(int A[], int esquerdo, int direito) {
	int x, i, j, temp;

	x = A[direito]; // pivo
	i = esquerdo - 1;

	for (j = esquerdo; j <= direito - 1; ++j) {
		if (A[j] <= x) {
			i++;
			// trocar
			temp = A[i];
			A[i] = A[j];
			A[j] = temp;
		}
	}

	// reposicionar o pivo
	temp = A[i + 1];
	A[i + 1] = A[direito];
	A[direito] = temp;
	return (i + 1);
}

void quick_sequencial (int A[], int esquerdo, int direito) {
	if (esquerdo < direito) {
		int q = particao_quick_sequencial(A, esquerdo, direito);
		quick_sequencial(A, esquerdo, q - 1);
		quick_sequencial(A, q + 1, direito);
	}
}

int main(int argc, char const *argv[]) {
	printf("Insertion Sort:\n");
	int a[] = {4,2,1,3,5,10,7,9,8,6};
	int tam = sizeof(a)/sizeof(int);
	imprime_array(a, tam);
	insertion_sequencial(a, tam);
	imprime_array(a, tam);

	printf("Quick Sort:\n");
	int b[] = {4,2,1,3,5,10,7,9,8,6};
	imprime_array(b, tam);
	quick_sequencial(b, 0, tam-1);
	imprime_array(b, sizeof(b)/sizeof(int));
	return 0;
}