<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use RuntimeException;

abstract class TestCase extends BaseTestCase
{
    /**
     * Pengaman: RefreshDatabase menghapus semua tabel, jadi jangan pernah jalan di database asli
     * (mis. ketika env Docker meng-override phpunit.xml).
     */
    protected function setUpTraits()
    {
        $connection = config('database.default');
        $database = config("database.connections.{$connection}.database");

        if ($connection !== 'sqlite' || $database !== ':memory:') {
            throw new RuntimeException("Test dibatalkan: koneksi DB [{$connection}:{$database}] bukan sqlite :memory:.");
        }

        return parent::setUpTraits();
    }
}
