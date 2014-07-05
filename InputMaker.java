import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;

import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.Random;


public final class InputMaker
{

	private Set<Integer> getIntegerSet(final int setSize){

		final Set<Integer> integerSet = new LinkedHashSet<>( setSize );

		final Random random = new Random( System.nanoTime() );

		int insertedIntegers = 0;
		
		while( insertedIntegers < setSize ){
			int integerToInsert = random.nextInt( setSize );

			while( integerSet.contains( integerToInsert ) ){
				integerToInsert = random.nextInt( setSize );
			}

			integerSet.add( integerToInsert );

			insertedIntegers++;
		}

		return Collections.unmodifiableSet( integerSet );
	}

	private String getStringToPrint( final Set<Integer> integerSet ){
		
		final StringBuilder strb = new StringBuilder();

		int printedIntegers = 0;
		
		for( Iterator<Integer> iterator = integerSet.iterator() ;
			 iterator.hasNext() ;  ){

			printedIntegers++;

			strb.append( iterator.next() );
			strb.append( " " );
			
			// if( printedIntegers%15 == 0){
			// 	strb.append("\n");
			// }

		}

		return strb.toString();
	}

	private void ensureOutputFileExists( final File outputFile ){
		if( ! outputFile.exists() ){
			try{
				outputFile.createNewFile();
			} catch (IOException e){
				throw new RuntimeException( "Arquivo de saída não pode ser criado" , e);
			}
		}
	} 

	private void printIntegerSet( final Set<Integer> integerSet, final String outputFilePath ){
		
		final File outputFile = new File( outputFilePath );

		ensureOutputFileExists( outputFile );
		
		final String stringToPrint = getStringToPrint( integerSet );

		PrintWriter writer = null;

		try{
			
			writer = new PrintWriter( outputFile );

			writer.print( stringToPrint );

		} catch(IOException e) {
			throw new RuntimeException( "Não escreveu corretamente a saída", e );
		} finally {
			if( writer != null ){
				writer.flush();
				writer.close();
			}
		}
		
	}

	private String getOutputFilePath( final String outputFileName ){
		
		final String currentUserDir = System.getProperty( "user.dir" );

		final StringBuilder strb = new StringBuilder( currentUserDir );

		strb.append("//").append(outputFileName);

		return strb.toString();
	}

	public static void main(String[] args) {
		
		if( args.length < 2 ){
			System.err.println("\tWRONG!");
			System.err.println("\njava InputMaker <numero de inteiros> <nome do arquivo de saida>\n");
		} else {
			final InputMaker maker = new InputMaker();

			final int setSize = Integer.valueOf( args[0] );

			final Set<Integer> integerSet = maker.getIntegerSet( setSize );

			final String outputFilePath = maker.getOutputFilePath( args[1] );

			maker.printIntegerSet( integerSet, outputFilePath );

		}
		

	}

}