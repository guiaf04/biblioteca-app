package com.biblioteca.service;

import com.biblioteca.model.Livro;
import com.biblioteca.repository.LivroRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LivroServiceTest {

    @Mock
    private LivroRepository livroRepository;

    @InjectMocks
    private LivroService livroService;

    private Livro livroTeste;

    @BeforeEach
    void setUp() {
        livroTeste = new Livro();
        livroTeste.setId(1L);
        livroTeste.setTitulo("Dom Casmurro");
        livroTeste.setAutor("Machado de Assis");
        livroTeste.setIsbn("978-85-359-0277-5");
        livroTeste.setAnoPublicacao(1899);
        livroTeste.setEditora("Companhia das Letras");
        livroTeste.setDescricao("Romance clássico da literatura brasileira");
        livroTeste.setDisponivel(true);
    }

    @Test
    void testListarTodos() {
        // Arrange
        List<Livro> livrosEsperados = Arrays.asList(livroTeste);
        when(livroRepository.findAll()).thenReturn(livrosEsperados);

        // Act
        List<Livro> resultado = livroService.listarTodos();

        // Assert
        assertEquals(1, resultado.size());
        assertEquals(livroTeste.getTitulo(), resultado.get(0).getTitulo());
        verify(livroRepository, times(1)).findAll();
    }

    @Test
    void testBuscarPorId() {
        // Arrange
        when(livroRepository.findById(1L)).thenReturn(Optional.of(livroTeste));

        // Act
        Optional<Livro> resultado = livroService.buscarPorId(1L);

        // Assert
        assertTrue(resultado.isPresent());
        assertEquals(livroTeste.getTitulo(), resultado.get().getTitulo());
        verify(livroRepository, times(1)).findById(1L);
    }

    @Test
    void testBuscarPorIdNaoEncontrado() {
        // Arrange
        when(livroRepository.findById(999L)).thenReturn(Optional.empty());

        // Act
        Optional<Livro> resultado = livroService.buscarPorId(999L);

        // Assert
        assertFalse(resultado.isPresent());
        verify(livroRepository, times(1)).findById(999L);
    }

    @Test
    void testSalvarLivroNovo() {
        // Arrange
        Livro novoLivro = new Livro();
        novoLivro.setTitulo("O Cortiço");
        novoLivro.setAutor("Aluísio Azevedo");
        novoLivro.setIsbn("978-85-359-0123-4");
        novoLivro.setAnoPublicacao(1890);

        when(livroRepository.findByIsbn(anyString())).thenReturn(Optional.empty());
        when(livroRepository.save(any(Livro.class))).thenReturn(novoLivro);

        // Act
        Livro resultado = livroService.salvar(novoLivro);

        // Assert
        assertEquals(novoLivro.getTitulo(), resultado.getTitulo());
        verify(livroRepository, times(1)).findByIsbn(novoLivro.getIsbn());
        verify(livroRepository, times(1)).save(novoLivro);
    }

    @Test
    void testSalvarLivroComIsbnExistente() {
        // Arrange
        Livro novoLivro = new Livro();
        novoLivro.setIsbn("978-85-359-0277-5"); // ISBN já existente

        when(livroRepository.findByIsbn(anyString())).thenReturn(Optional.of(livroTeste));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            livroService.salvar(novoLivro);
        });

        assertEquals("Já existe um livro com este ISBN", exception.getMessage());
        verify(livroRepository, times(1)).findByIsbn(novoLivro.getIsbn());
        verify(livroRepository, never()).save(any(Livro.class));
    }

    @Test
    void testAtualizar() {
        // Arrange
        Livro livroAtualizado = new Livro();
        livroAtualizado.setTitulo("Dom Casmurro - Edição Especial");
        livroAtualizado.setAutor("Machado de Assis");
        livroAtualizado.setIsbn("978-85-359-0277-5");
        livroAtualizado.setAnoPublicacao(1899);
        livroAtualizado.setDisponivel(false);

        when(livroRepository.findById(1L)).thenReturn(Optional.of(livroTeste));
        when(livroRepository.save(any(Livro.class))).thenReturn(livroAtualizado);

        // Act
        Livro resultado = livroService.atualizar(1L, livroAtualizado);

        // Assert
        assertEquals(livroAtualizado.getTitulo(), resultado.getTitulo());
        assertEquals(livroAtualizado.getDisponivel(), resultado.getDisponivel());
        verify(livroRepository, times(1)).findById(1L);
        verify(livroRepository, times(1)).save(any(Livro.class));
    }

    @Test
    void testAtualizarLivroNaoEncontrado() {
        // Arrange
        Livro livroAtualizado = new Livro();
        when(livroRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            livroService.atualizar(999L, livroAtualizado);
        });

        assertEquals("Livro não encontrado", exception.getMessage());
        verify(livroRepository, times(1)).findById(999L);
        verify(livroRepository, never()).save(any(Livro.class));
    }

    @Test
    void testDeletar() {
        // Arrange
        when(livroRepository.existsById(1L)).thenReturn(true);

        // Act
        livroService.deletar(1L);

        // Assert
        verify(livroRepository, times(1)).existsById(1L);
        verify(livroRepository, times(1)).deleteById(1L);
    }

    @Test
    void testDeletarLivroNaoEncontrado() {
        // Arrange
        when(livroRepository.existsById(999L)).thenReturn(false);

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            livroService.deletar(999L);
        });

        assertEquals("Livro não encontrado", exception.getMessage());
        verify(livroRepository, times(1)).existsById(999L);
        verify(livroRepository, never()).deleteById(any());
    }

    @Test
    void testBuscarPorTermo() {
        // Arrange
        List<Livro> livrosEsperados = Arrays.asList(livroTeste);
        when(livroRepository.buscarPorTermo("Machado")).thenReturn(livrosEsperados);

        // Act
        List<Livro> resultado = livroService.buscarPorTermo("Machado");

        // Assert
        assertEquals(1, resultado.size());
        assertEquals(livroTeste.getTitulo(), resultado.get(0).getTitulo());
        verify(livroRepository, times(1)).buscarPorTermo("Machado");
    }

    @Test
    void testContarTotal() {
        // Arrange
        when(livroRepository.count()).thenReturn(5L);

        // Act
        long resultado = livroService.contarTotal();

        // Assert
        assertEquals(5L, resultado);
        verify(livroRepository, times(1)).count();
    }

    @Test
    void testBuscarDisponiveis() {
        // Arrange
        List<Livro> livrosDisponiveis = Arrays.asList(livroTeste);
        when(livroRepository.findByDisponivel(true)).thenReturn(livrosDisponiveis);

        // Act
        List<Livro> resultado = livroService.buscarDisponiveis();

        // Assert
        assertEquals(1, resultado.size());
        assertTrue(resultado.get(0).getDisponivel());
        verify(livroRepository, times(1)).findByDisponivel(true);
    }
}

