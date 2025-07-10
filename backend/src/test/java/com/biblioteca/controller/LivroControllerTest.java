package com.biblioteca.controller;

import com.biblioteca.model.Livro;
import com.biblioteca.service.LivroService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(LivroController.class)
class LivroControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LivroService livroService;

    @Autowired
    private ObjectMapper objectMapper;

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
    void testListarTodos() throws Exception {
        // Arrange
        List<Livro> livros = Arrays.asList(livroTeste);
        when(livroService.listarTodos()).thenReturn(livros);

        // Act & Assert
        mockMvc.perform(get("/api/livros"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].titulo").value("Dom Casmurro"))
                .andExpect(jsonPath("$[0].autor").value("Machado de Assis"));

        verify(livroService, times(1)).listarTodos();
    }

    @Test
    void testBuscarPorId() throws Exception {
        // Arrange
        when(livroService.buscarPorId(1L)).thenReturn(Optional.of(livroTeste));

        // Act & Assert
        mockMvc.perform(get("/api/livros/1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.titulo").value("Dom Casmurro"))
                .andExpect(jsonPath("$.autor").value("Machado de Assis"));

        verify(livroService, times(1)).buscarPorId(1L);
    }

    @Test
    void testBuscarPorIdNaoEncontrado() throws Exception {
        // Arrange
        when(livroService.buscarPorId(999L)).thenReturn(Optional.empty());

        // Act & Assert
        mockMvc.perform(get("/api/livros/999"))
                .andExpect(status().isNotFound());

        verify(livroService, times(1)).buscarPorId(999L);
    }

    @Test
    void testCriarLivro() throws Exception {
        // Arrange
        Livro novoLivro = new Livro();
        novoLivro.setTitulo("O Cortiço");
        novoLivro.setAutor("Aluísio Azevedo");
        novoLivro.setIsbn("978-85-359-0123-4");
        novoLivro.setAnoPublicacao(1890);
        novoLivro.setDisponivel(true);

        Livro livroSalvo = new Livro();
        livroSalvo.setId(2L);
        livroSalvo.setTitulo(novoLivro.getTitulo());
        livroSalvo.setAutor(novoLivro.getAutor());
        livroSalvo.setIsbn(novoLivro.getIsbn());
        livroSalvo.setAnoPublicacao(novoLivro.getAnoPublicacao());
        livroSalvo.setDisponivel(novoLivro.getDisponivel());

        when(livroService.salvar(any(Livro.class))).thenReturn(livroSalvo);

        // Act & Assert
        mockMvc.perform(post("/api/livros")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(novoLivro)))
                .andExpect(status().isCreated())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(2))
                .andExpect(jsonPath("$.titulo").value("O Cortiço"));

        verify(livroService, times(1)).salvar(any(Livro.class));
    }

    @Test
    void testCriarLivroComDadosInvalidos() throws Exception {
        // Arrange
        Livro livroInvalido = new Livro();
        // Não definir campos obrigatórios

        // Act & Assert
        mockMvc.perform(post("/api/livros")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(livroInvalido)))
                .andExpect(status().isBadRequest());

        verify(livroService, never()).salvar(any(Livro.class));
    }

    @Test
    void testAtualizarLivro() throws Exception {
        // Arrange
        Livro livroAtualizado = new Livro();
        livroAtualizado.setTitulo("Dom Casmurro - Edição Especial");
        livroAtualizado.setAutor("Machado de Assis");
        livroAtualizado.setIsbn("978-85-359-0277-5");
        livroAtualizado.setAnoPublicacao(1899);
        livroAtualizado.setDisponivel(false);

        when(livroService.atualizar(eq(1L), any(Livro.class))).thenReturn(livroAtualizado);

        // Act & Assert
        mockMvc.perform(put("/api/livros/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(livroAtualizado)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.titulo").value("Dom Casmurro - Edição Especial"))
                .andExpect(jsonPath("$.disponivel").value(false));

        verify(livroService, times(1)).atualizar(eq(1L), any(Livro.class));
    }

    @Test
    void testDeletarLivro() throws Exception {
        // Arrange
        doNothing().when(livroService).deletar(1L);

        // Act & Assert
        mockMvc.perform(delete("/api/livros/1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.mensagem").value("Livro deletado com sucesso"));

        verify(livroService, times(1)).deletar(1L);
    }

    @Test
    void testDeletarLivroNaoEncontrado() throws Exception {
        // Arrange
        doThrow(new RuntimeException("Livro não encontrado")).when(livroService).deletar(999L);

        // Act & Assert
        mockMvc.perform(delete("/api/livros/999"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.erro").value("Livro não encontrado"));

        verify(livroService, times(1)).deletar(999L);
    }

    @Test
    void testBuscarPorTermo() throws Exception {
        // Arrange
        List<Livro> livros = Arrays.asList(livroTeste);
        when(livroService.buscarPorTermo("Machado")).thenReturn(livros);

        // Act & Assert
        mockMvc.perform(get("/api/livros/buscar")
                        .param("termo", "Machado"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].autor").value("Machado de Assis"));

        verify(livroService, times(1)).buscarPorTermo("Machado");
    }

    @Test
    void testObterEstatisticas() throws Exception {
        // Arrange
        when(livroService.contarTotal()).thenReturn(10L);
        when(livroService.contarDisponiveis()).thenReturn(8L);

        // Act & Assert
        mockMvc.perform(get("/api/livros/estatisticas"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.total").value(10))
                .andExpect(jsonPath("$.disponiveis").value(8));

        verify(livroService, times(1)).contarTotal();
        verify(livroService, times(1)).contarDisponiveis();
    }
}

