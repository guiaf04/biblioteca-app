package com.biblioteca.controller;

import com.biblioteca.model.Livro;
import com.biblioteca.service.LivroService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/livros")
@CrossOrigin(origins = "*")
public class LivroController {
    
    @Autowired
    private LivroService livroService;
    
    @GetMapping
    public ResponseEntity<List<Livro>> listarTodos() {
        List<Livro> livros = livroService.listarTodos();
        return ResponseEntity.ok(livros);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Livro> buscarPorId(@PathVariable Long id) {
        Optional<Livro> livro = livroService.buscarPorId(id);
        return livro.map(ResponseEntity::ok)
                   .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/buscar")
    public ResponseEntity<List<Livro>> buscar(@RequestParam String termo) {
        List<Livro> livros = livroService.buscarPorTermo(termo);
        return ResponseEntity.ok(livros);
    }
    
    @GetMapping("/disponiveis")
    public ResponseEntity<List<Livro>> listarDisponiveis() {
        List<Livro> livros = livroService.buscarDisponiveis();
        return ResponseEntity.ok(livros);
    }
    
    @PostMapping
    public ResponseEntity<?> criar(@Valid @RequestBody Livro livro) {
        try {
            Livro novoLivro = livroService.salvar(livro);
            return ResponseEntity.status(HttpStatus.CREATED).body(novoLivro);
        } catch (RuntimeException e) {
            Map<String, String> erro = new HashMap<>();
            erro.put("erro", e.getMessage());
            return ResponseEntity.badRequest().body(erro);
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<?> atualizar(@PathVariable Long id, @Valid @RequestBody Livro livro) {
        try {
            Livro livroAtualizado = livroService.atualizar(id, livro);
            return ResponseEntity.ok(livroAtualizado);
        } catch (RuntimeException e) {
            Map<String, String> erro = new HashMap<>();
            erro.put("erro", e.getMessage());
            return ResponseEntity.badRequest().body(erro);
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletar(@PathVariable Long id) {
        try {
            livroService.deletar(id);
            Map<String, String> sucesso = new HashMap<>();
            sucesso.put("mensagem", "Livro deletado com sucesso");
            return ResponseEntity.ok(sucesso);
        } catch (RuntimeException e) {
            Map<String, String> erro = new HashMap<>();
            erro.put("erro", e.getMessage());
            return ResponseEntity.badRequest().body(erro);
        }
    }
    
    @GetMapping("/estatisticas")
    public ResponseEntity<Map<String, Long>> obterEstatisticas() {
        Map<String, Long> estatisticas = new HashMap<>();
        estatisticas.put("total", livroService.contarTotal());
        estatisticas.put("disponiveis", livroService.contarDisponiveis());
        return ResponseEntity.ok(estatisticas);
    }
}

