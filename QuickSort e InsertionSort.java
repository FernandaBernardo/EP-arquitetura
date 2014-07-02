//QUICKSORT

private void quickSort(int[] A, int p, int r) {
	if (p < r) {
		int q = particao(A, p, r);
		quickSort(A, p, q - 1);
		quickSort(A, q + 1, r);
	}
}

protected int particao(int[] A, int p, int r) {
	int x, i, j, temp;

	x = A[r]; // pivo
	i = p - 1;

	for (j = p; j <= r - 1; ++j) {
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
	A[i + 1] = A[r];
	A[r] = temp;
	return (i + 1);
}


//INSERTION SORT

public void ordena(int[] A) {
		int i, j, v;
		int fim = A.length;

		for (i = 1; i < fim; i++) {
			v = A[i];
			j = i;
			while ((j > 0) && (A[j - 1] > v)) {
				A[j] = A[j - 1];
				j = j - 1;
			}
			A[j] = v;
		}
	}