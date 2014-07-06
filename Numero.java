class Numero {
	public static void main(String[] args) {
		separaNum(234);
	}

	static void separaNum(int n) {
		int potencia = 1;
		int quociente, resto;

		while (n/potencia >= 10) {
			potencia *= 10;
		}

		while (potencia > 0) {
			if (n >= potencia) {
				quociente = n / potencia;
				resto = n % potencia;
				n = resto;
				System.out.println(quociente);
			} else {
				System.out.println('0');
			}
			potencia /= 10;
		}
	}
}